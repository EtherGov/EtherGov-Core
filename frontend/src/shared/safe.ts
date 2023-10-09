import { Config } from "@/utils/interface";
import {
  EthersAdapter,
  SafeAccountConfig,
  SafeFactory,
} from "@safe-global/protocol-kit";
import { Contract, ethers } from "ethers";
import RPC from "../../public/RPC.json";
import { constants } from "buffer";
import { supabase } from "./supabase";

export async function createMultisig(config: Config) {
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();

  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: signer,
  });

  const safeFactory = await SafeFactory.create({
    ethAdapter,
  });

  const safeAccountConfig: SafeAccountConfig = {
    owners: config.DEPLOY_SAFE.OWNERS,
    threshold: config.DEPLOY_SAFE.THRESHOLD,
  };

  const saltNonce = config.DEPLOY_SAFE.SALT_NONCE;

  const predictedDeploySafeAddress = await safeFactory.predictSafeAddress(
    safeAccountConfig,
    saltNonce.toString()
  );

  console.log("Predicted deployed Safe address:", predictedDeploySafeAddress);

  function callback(txHash: string) {
    console.log("Transaction hash:", txHash);
  }

  // Deploy Safe
  const safe = await safeFactory.deploySafe({
    safeAccountConfig,
    saltNonce: saltNonce.toString(),
    callback,
  });

  const safeAddress = await safe.getAddress();

  console.log("Deployed Safe:", safeAddress);

  saveSafeAddress(config.DEPLOY_SAFE.OWNERS, safeAddress);
}

//Add Module
export async function addModule(safeAddress: string, moduleAddress: string) {
  try {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();

    const abi = [
      {
        constant: true,
        inputs: [{ name: "", type: "address" }],
        name: "enableModule",
        payable: false,
        type: "function",
      },
    ];

    const contract = new Contract(safeAddress, abi, signer);
    const tx = await contract.enableModule(moduleAddress);
    const result = await tx.wait();
    console.log(result);
    return result;
  } catch (e) {
    throw new Error("Error adding module");
  }
}

export async function saveSafeAddress(owners: string[], safeAddress: string) {
  try {
    const result = await supabase.from("multisig_array").insert({
      contract_address: safeAddress,
      owners: owners,
    });
    if (!result) {
      throw new Error("Error saving safe address");
    }
    console.log(result.data);
  } catch (e) {
    throw new Error("Error saving safe address");
  }
}

export async function getSafeAddress(owners: string[]) {
  try {
    const result = await supabase
      .from("multisig_array")
      .select("*")
      .contains("owners", owners);
    if (!result.data) {
      throw new Error("No safe address found");
    }
    console.log(result.data);
    return result.data[0].contract_address;
  } catch (e) {
    throw new Error("Error getting safe address");
  }
}

export async function findRPCUrl(chainId: number) {
  try {
    const rpc = RPC.filter((rpc) => rpc.CHAIN_ID === chainId)[0];
    return rpc.RPC_URL;
  } catch (e) {
    throw new Error("RPC not found");
  }
}
