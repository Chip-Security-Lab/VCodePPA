module gray_counter_mealy(
    input wire clock, reset_n, enable, up_down,
    output reg [3:0] gray_out
);
    reg [3:0] binary_count, next_binary;
    
    always @(posedge clock or negedge reset_n)
        if (!reset_n) binary_count <= 4'b0000;
        else if (enable) binary_count <= next_binary;
    
    always @(*) begin
        if (up_down)
            next_binary = binary_count - 1'b1;
        else
            next_binary = binary_count + 1'b1;
            
        // Convert binary to Gray code
        gray_out = {binary_count[3], binary_count[3:1] ^ binary_count[2:0]};
    end
endmodule