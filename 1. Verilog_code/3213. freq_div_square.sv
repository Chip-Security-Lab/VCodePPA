module freq_div_square(
    input wire master_clk,
    input wire rst_b,
    input wire [15:0] div_factor,
    output reg clk_out
);
    reg [15:0] div_count;
    
    always @(posedge master_clk or negedge rst_b) begin
        if (!rst_b) begin
            div_count <= 16'h0000;
            clk_out <= 1'b0;
        end else begin
            if (div_count >= (div_factor - 1)) begin
                div_count <= 16'h0000;
                clk_out <= ~clk_out;
            end else begin
                div_count <= div_count + 16'h0001;
            end
        end
    end
endmodule
