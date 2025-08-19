module temp_compensated_codec (
    input clk, rst_n,
    input [7:0] r_in, g_in, b_in,
    input [7:0] temperature,
    input comp_enable,
    output reg [15:0] display_out
);
    // Temperature compensation factors
    wire [3:0] r_factor = temperature > 8'd80 ? 4'd12 : 
                          temperature > 8'd60 ? 4'd13 :
                          temperature > 8'd40 ? 4'd14 :
                          temperature > 8'd20 ? 4'd15 : 4'd15;
    wire [3:0] g_factor = temperature > 8'd80 ? 4'd14 : 
                          temperature > 8'd60 ? 4'd15 :
                          temperature > 8'd40 ? 4'd15 :
                          temperature > 8'd20 ? 4'd14 : 4'd13;
    wire [3:0] b_factor = temperature > 8'd80 ? 4'd15 : 
                          temperature > 8'd60 ? 4'd14 :
                          temperature > 8'd40 ? 4'd13 :
                          temperature > 8'd20 ? 4'd12 : 4'd11;
    
    // Adjusted RGB values
    wire [11:0] r_adj = comp_enable ? (r_in * r_factor) : {r_in, 4'b0000};
    wire [11:0] g_adj = comp_enable ? (g_in * g_factor) : {g_in, 4'b0000};
    wire [11:0] b_adj = comp_enable ? (b_in * b_factor) : {b_in, 4'b0000};
    
    // RGB to RGB565 conversion with temperature compensation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            display_out <= 16'h0000;
        else
            display_out <= {r_adj[11:7], g_adj[11:6], b_adj[11:7]};
    end
endmodule