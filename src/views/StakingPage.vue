<template>
  <div class="homepage">
    <staking-ethereum/>
  </div>
</template>

<script>
import StakingEthereum from "../components/staking/Staking";
export default {
  name: "CommunityPage",
  components: {StakingEthereum}
}
</script>