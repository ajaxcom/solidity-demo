import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { network } from "hardhat";
import { encodeFunctionData } from "viem";

describe("Governance + Timelock + Linear Vesting", async function () {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();
  const testClient = await viem.getTestClient();

  it("多签排队并执行时间锁操作，成功更改 beneficiary", async function () {
    const [owner1, owner2, owner3, beneficiary, newBeneficiary] = await viem.getWalletClients();

    const multiSig = await viem.deployContract("SimpleMultiSig", [
      [owner1.account.address, owner2.account.address, owner3.account.address],
      2n,
    ]);

    const minDelay = 3600n;
    const timeLock = await viem.deployContract("SimpleTimeLock", [multiSig.address, minDelay]);

    const totalAmount = 1_000_000n * 10n ** 18n;
    const token = await viem.deployContract("MyToken", ["Demo Token", "DMT", totalAmount]);

    const now = BigInt((await publicClient.getBlock()).timestamp);
    const start = now + 60n;
    const duration = 30n * 24n * 60n * 60n;

    const vestingVault = await viem.deployContract("LinearVestingVault", [
      token.address,
      beneficiary.account.address,
      start,
      duration,
      totalAmount,
      timeLock.address,
    ]);

    await token.write.transfer([vestingVault.address, totalAmount]);

    // 需要通过 timelock 调用 vestingVault.setBeneficiary(newBeneficiary)
    const setBeneficiaryData = encodeFunctionData({
      abi: vestingVault.abi,
      functionName: "setBeneficiary",
      args: [newBeneficiary.account.address],
    });

    const currentTs = BigInt((await publicClient.getBlock()).timestamp);
    const eta = currentTs + minDelay + 10n;

    // 多签将 timelock.queue(...) 这笔调用提交并执行
    const queueData = encodeFunctionData({
      abi: timeLock.abi,
      functionName: "queue",
      args: [vestingVault.address, 0n, setBeneficiaryData, eta],
    });

    await multiSig.write.submitTx([timeLock.address, 0n, queueData], {
      account: owner1.account,
    });
    await multiSig.write.confirmTx([0n], { account: owner1.account });
    await multiSig.write.confirmTx([0n], { account: owner2.account });
    await multiSig.write.executeTx([0n], { account: owner1.account });

    const opId = await timeLock.read.getOpId([vestingVault.address, 0n, setBeneficiaryData, eta]);
    assert.equal(await timeLock.read.queued([opId]), true);

    // 时间前进到 eta 之后，执行 timelock
    await testClient.increaseTime({ seconds: Number(minDelay + 20n) });
    await testClient.mine({ blocks: 1 });
    await timeLock.write.execute([vestingVault.address, 0n, setBeneficiaryData, eta], {
      account: owner3.account,
    });

    assert.equal(
      (await vestingVault.read.beneficiary()).toLowerCase(),
      newBeneficiary.account.address.toLowerCase(),
    );
  });

  it("线性锁仓释放金额随时间增加并累计正确", async function () {
    const [owner1, owner2, owner3, beneficiary] = await viem.getWalletClients();

    const multiSig = await viem.deployContract("SimpleMultiSig", [
      [owner1.account.address, owner2.account.address, owner3.account.address],
      2n,
    ]);

    const minDelay = 3600n;
    const timeLock = await viem.deployContract("SimpleTimeLock", [multiSig.address, minDelay]);

    const totalAmount = 1_000_000n * 10n ** 18n;
    const token = await viem.deployContract("MyToken", ["Demo Token", "DMT", totalAmount]);

    const now = BigInt((await publicClient.getBlock()).timestamp);
    const start = now + 10n;
    const duration = 100n;

    const vestingVault = await viem.deployContract("LinearVestingVault", [
      token.address,
      beneficiary.account.address,
      start,
      duration,
      totalAmount,
      timeLock.address,
    ]);

    await token.write.transfer([vestingVault.address, totalAmount]);

    // 先推进到 start+20 秒：理论可释放 20%
    await testClient.increaseTime({ seconds: 35 });
    await testClient.mine({ blocks: 1 });

    const releasableAt20 = await vestingVault.read.releasable();
    assert.ok(releasableAt20 > 0n, "releasable should be > 0 after start");

    const b0 = await token.read.balanceOf([beneficiary.account.address]);
    await vestingVault.write.release({ account: owner1.account });
    const b1 = await token.read.balanceOf([beneficiary.account.address]);
    const firstReleased = b1 - b0;
    // release 交易本身会推进一个区块时间，实际释放值可能略大于调用前读取值
    assert.ok(firstReleased >= releasableAt20, "first release should be >= pre-read releasable");

    // 再推进 40 秒：应继续释放，且累计增加
    await testClient.increaseTime({ seconds: 40 });
    await testClient.mine({ blocks: 1 });

    const releasableLater = await vestingVault.read.releasable();
    assert.ok(releasableLater > 0n, "releasable should continue increasing");

    await vestingVault.write.release({ account: owner2.account });
    const b2 = await token.read.balanceOf([beneficiary.account.address]);
    assert.ok(b2 - b1 >= releasableLater, "second release should be >= pre-read releasable");

    // 推进到结束后，全部额度应可被领取完
    await testClient.increaseTime({ seconds: 100 });
    await testClient.mine({ blocks: 1 });
    const finalReleasable = await vestingVault.read.releasable();
    if (finalReleasable > 0n) {
      await vestingVault.write.release({ account: owner3.account });
    }

    const finalBalance = await token.read.balanceOf([beneficiary.account.address]);
    assert.equal(finalBalance, totalAmount);
    assert.equal(await vestingVault.read.released(), totalAmount);
  });
});
