//SystemVerilog
module status_buffer (
    input wire clk,
    input wire [7:0] status_in,
    input wire update,
    input wire clear,
    output reg [7:0] status_out
);
    // Pipeline registers
    reg [1:0] ctrl_pipe;
    reg [7:0] status_in_pipe;
    reg [7:0] status_out_pipe;
    
    // Stage 1: Extract control signals and register inputs
    always @(posedge clk) begin
        ctrl_pipe <= {clear, update};
        status_in_pipe <= status_in;
        status_out_pipe <= status_out;
    end
    
    // Stage 2: Process logic with pipelined inputs
    always @(posedge clk) begin
        case (ctrl_pipe)
            2'b10, 2'b11: status_out <= 8'b0;                      // clear优先
            2'b01:        status_out <= status_out_pipe | status_in_pipe;  // 仅更新
            2'b00:        status_out <= status_out_pipe;           // 保持当前值
            default:      status_out <= status_out_pipe;           // 默认保持
        endcase
    end
endmodule