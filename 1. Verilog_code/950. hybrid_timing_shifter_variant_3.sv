//SystemVerilog
module hybrid_timing_shifter (
    input clk,
    input [7:0] din,
    input [2:0] shift,
    input valid,
    output reg ready,
    output reg [7:0] dout,
    output reg dout_valid
);
    reg [7:0] reg_stage;
    wire [7:0] comb_stage;
    reg processing;
    
    assign comb_stage = reg_stage << shift;
    
    always @(posedge clk) begin
        if (valid && ready) begin
            reg_stage <= din;
            processing <= 1'b1;
            ready <= 1'b0;
        end
        
        if (processing) begin
            dout <= comb_stage;
            dout_valid <= 1'b1;
            processing <= 1'b0;
            ready <= 1'b1;
        end else if (dout_valid) begin
            dout_valid <= 1'b0;
        end
    end
    
    initial begin
        ready = 1'b1;
        dout_valid = 1'b0;
        processing = 1'b0;
    end
endmodule