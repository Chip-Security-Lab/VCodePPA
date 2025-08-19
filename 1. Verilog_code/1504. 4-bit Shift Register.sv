module shift_reg_4bit (
    input wire clk, rst, load_en, shift_en, serial_in,
    input wire [3:0] parallel_data,
    output wire serial_out,
    output wire [3:0] parallel_out
);
    reg [3:0] sr;
    
    always @(posedge clk) begin
        if (rst)
            sr <= 4'b0000;
        else if (load_en)
            sr <= parallel_data;
        else if (shift_en)
            sr <= {sr[2:0], serial_in};
    end
    
    assign serial_out = sr[3];
    assign parallel_out = sr;
endmodule
