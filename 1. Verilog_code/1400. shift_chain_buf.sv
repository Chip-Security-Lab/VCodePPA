module shift_chain_buf #(parameter DW=8, DEPTH=4) (
    input clk, en,
    input serial_in,
    input [DW-1:0] parallel_in,
    input load,
    input rst, // Added reset signal
    output serial_out,
    output [DW*DEPTH-1:0] parallel_out
);
    reg [DW-1:0] shift_reg [0:DEPTH-1];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for(i=0; i<DEPTH; i=i+1)
                shift_reg[i] <= 0;
        end else if(en) begin
            if(load) begin
                shift_reg[0] <= parallel_in;
                shift_reg[1] <= parallel_in;
                shift_reg[2] <= parallel_in;
                shift_reg[3] <= parallel_in;
            end
            else begin
                shift_reg[3] <= shift_reg[2];
                shift_reg[2] <= shift_reg[1];
                shift_reg[1] <= shift_reg[0];
                shift_reg[0] <= {{(DW-1){1'b0}}, serial_in}; // Fixed concatenation
            end
        end
    end
    
    assign serial_out = shift_reg[DEPTH-1][0];
    
    genvar g;
    generate
        for(g=0; g<DEPTH; g=g+1)
            assign parallel_out[g*DW +: DW] = shift_reg[g];
    endgenerate
endmodule