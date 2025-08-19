module pulse_width_clock_gate (
    input  wire clk_in,
    input  wire trigger,
    input  wire rst_n,
    input  wire [3:0] width,
    output wire clk_out
);
    reg [3:0] counter;
    reg enable;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            enable <= 1'b0;
        end else if (trigger) begin
            counter <= width;
            enable <= 1'b1;
        end else if (|counter) begin
            counter <= counter - 1'b1;
            enable <= (counter > 4'd1) ? 1'b1 : 1'b0;
        end
    end
    
    assign clk_out = clk_in & enable;
endmodule