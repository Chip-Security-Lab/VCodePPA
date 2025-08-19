//SystemVerilog
module johnson_counter (
    input wire clk, arst,
    output wire [3:0] count_out
);
    reg [3:0] count;
    
    // The Johnson counter already has a simple feedback path
    // No complex combinational logic requiring pipeline registers
    always @(posedge clk or posedge arst) begin
        if (arst)
            count <= 4'b0000;
        else
            count <= {count[2:0], ~count[3]};
    end
    
    // Output registered to reduce output load and improve timing
    reg [3:0] count_out_reg;
    always @(posedge clk or posedge arst) begin
        if (arst)
            count_out_reg <= 4'b0000;
        else
            count_out_reg <= count;
    end
    
    assign count_out = count_out_reg;
endmodule