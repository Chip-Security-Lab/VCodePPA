module dds_div #(parameter FTW=32'h1999_9999) (
    input clk, rst,
    output reg clk_out
);
reg [31:0] phase_acc;
always @(posedge clk) begin
    if(rst) begin
        phase_acc <= 0;
        clk_out <= 0;
    end else begin
        phase_acc <= phase_acc + FTW;
        clk_out <= phase_acc[31];
    end
end
endmodule
