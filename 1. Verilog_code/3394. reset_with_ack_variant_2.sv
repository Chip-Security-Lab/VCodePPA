//SystemVerilog
module reset_with_ack(
    input wire clk,
    input wire reset_req,
    input wire [3:0] ack_signals,
    output reg [3:0] reset_out,
    output reg reset_complete
);
    // Pipeline stage 1 registers
    reg reset_req_stage1;
    reg [3:0] ack_signals_stage1;
    
    // Pipeline stage 2 registers
    reg reset_req_stage2;
    reg [3:0] ack_signals_stage2;
    reg [3:0] reset_out_stage2;
    reg reset_complete_stage2;
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        reset_req_stage1 <= reset_req;
        ack_signals_stage1 <= ack_signals;
    end
    
    // Pipeline stage 2: Process logic
    always @(posedge clk) begin
        reset_req_stage2 <= reset_req_stage1;
        ack_signals_stage2 <= ack_signals_stage1;
        
        // 使用组合条件作为case表达式
        case ({reset_req_stage1, ack_signals_stage1 == 4'hF})
            2'b10, 2'b11: begin  // reset_req_stage1 = 1, 不论ack_signals_stage1的值
                reset_out_stage2 <= 4'hF;
                reset_complete_stage2 <= 1'b0;
            end
            2'b01: begin  // reset_req_stage1 = 0, ack_signals_stage1 = 4'hF
                reset_out_stage2 <= 4'h0;
                reset_complete_stage2 <= 1'b1;
            end
            default: begin  // 其他情况保持输出不变
                reset_out_stage2 <= reset_out_stage2;
                reset_complete_stage2 <= reset_complete_stage2;
            end
        endcase
    end
    
    // Pipeline stage 3: Register outputs
    always @(posedge clk) begin
        reset_out <= reset_out_stage2;
        reset_complete <= reset_complete_stage2;
    end
endmodule