//SystemVerilog
module ClockGating #(
    parameter SYNC_STAGES = 2
)(
    input clk, rst_n,
    input enable,
    input test_mode,
    output gated_clk
);
    reg [SYNC_STAGES-1:0] enable_sync;
    reg clock_gate;
    reg [1:0] gate_lut_addr;
    wire lut_output;
    
    // 条件反相减法器实现
    wire [1:0] sub_result;
    wire [1:0] sub_inv;
    wire sub_carry;
    
    // 减法器输入
    wire [1:0] sub_a = {1'b0, enable_sync[SYNC_STAGES-1]};
    wire [1:0] sub_b = {1'b0, clock_gate};
    
    // 条件反相减法器核心逻辑
    assign sub_inv = ~sub_b;
    assign {sub_carry, sub_result} = sub_a + sub_inv + 1'b1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            enable_sync <= {enable_sync[SYNC_STAGES-2:0], enable};
        end
    end
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clock_gate <= 1'b0;
        end else begin
            clock_gate <= sub_result[0];
        end
    end
    
    always @(*) begin
        gate_lut_addr = {test_mode, clock_gate};
    end
    
    assign lut_output = (gate_lut_addr == 2'b00) ? 1'b0 :
                        (gate_lut_addr == 2'b01) ? 1'b1 :
                        (gate_lut_addr == 2'b10) ? 1'b1 : 1'b1;
    
    assign gated_clk = clk & lut_output;
    
endmodule