module johnson_counter (
    input wire clk, arst,
    output wire [3:0] count_out
);
    reg [3:0] count;
    
    always @(posedge clk or posedge arst) begin
        if (arst)
            count <= 4'b0000;
        else
            count <= {count[2:0], ~count[3]};
    end
    
    assign count_out = count;
endmodule