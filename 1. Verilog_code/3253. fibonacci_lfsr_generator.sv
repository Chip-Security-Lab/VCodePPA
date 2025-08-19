module fibonacci_lfsr_generator (
    input wire clk_i,
    input wire arst_n_i,
    output wire [31:0] random_o
);
    reg [31:0] shift_register;
    wire feedback;
    
    assign feedback = shift_register[31] ^ shift_register[21] ^ 
                      shift_register[1] ^ shift_register[0];
    
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i)
            shift_register <= 32'h1;
        else
            shift_register <= {shift_register[30:0], feedback};
    end
    
    assign random_o = shift_register;
endmodule