//SystemVerilog
module MuxPipeline #(parameter W=16) (
    input wire clk,
    input wire [3:0][W-1:0] ch,
    input wire [1:0] sel,
    output reg [W-1:0] dout_reg
);

    // Pipeline stage registers
    reg [W-1:0] mux_stage;
    reg [W-1:0] pipe_stage;

    // Combined pipeline stages
    always @(posedge clk) begin
        mux_stage <= ch[sel];
        pipe_stage <= mux_stage;
        dout_reg <= pipe_stage;
    end

endmodule