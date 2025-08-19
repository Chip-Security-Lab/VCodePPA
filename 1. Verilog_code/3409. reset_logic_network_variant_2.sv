//SystemVerilog
module reset_logic_network(
    input wire [3:0] reset_sources,
    input wire [3:0] config_bits,
    output reg [3:0] reset_outputs
);
    always @(*) begin
        // 原表达式:(reset_sources[i] & (reset_sources[j] | ~config_bits[i])) | (reset_sources[j] & ~config_bits[i])
        // 可化简为:reset_sources[i] & reset_sources[j] | ~config_bits[i] & (reset_sources[i] | reset_sources[j])
        // 进一步化简为:~config_bits[i] & (reset_sources[i] | reset_sources[j]) | config_bits[i] & reset_sources[i] & reset_sources[j]
        // 最终化简为:(reset_sources[i] | reset_sources[j]) & (~config_bits[i] | reset_sources[i])
        
        reset_outputs[0] = (reset_sources[0] | reset_sources[1]) & (~config_bits[0] | reset_sources[0]);
        reset_outputs[1] = (reset_sources[1] | reset_sources[2]) & (~config_bits[1] | reset_sources[1]);
        reset_outputs[2] = (reset_sources[2] | reset_sources[3]) & (~config_bits[2] | reset_sources[2]);
        reset_outputs[3] = (reset_sources[3] | reset_sources[0]) & (~config_bits[3] | reset_sources[3]);
    end
endmodule