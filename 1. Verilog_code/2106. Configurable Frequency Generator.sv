module config_freq_gen(
    input master_clk,
    input rstn,
    input [7:0] freq_sel,
    output reg out_clk
);
    reg [7:0] counter;
    
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter <= 8'd0;
            out_clk <= 1'b0;
        end else begin
            if (counter >= freq_sel) begin
                counter <= 8'd0;
                out_clk <= ~out_clk;
            end else
                counter <= counter + 8'd1;
        end
    end
endmodule