module gray_counter_div (
    input wire clk, rst,
    output wire divided_clk
);
    reg [3:0] gray_count;
    wire [3:0] next_gray;
    
    // Calculate next gray code
    assign next_gray[3] = gray_count[3] ^ (gray_count[2] & gray_count[1] & gray_count[0]);
    assign next_gray[2] = gray_count[2] ^ (gray_count[1] & gray_count[0]);
    assign next_gray[1] = gray_count[1] ^ gray_count[0];
    assign next_gray[0] = ~gray_count[0];
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            gray_count <= 4'b0000;
        else
            gray_count <= next_gray;
    end
    
    assign divided_clk = gray_count[3];
endmodule