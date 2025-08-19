module subtractor_4bit_step (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);

    reg [3:0] borrow;
    reg [3:0] temp_diff;
    
    always @(*) begin
        // 第0位
        if (a[0] < b[0]) begin
            borrow[0] = 1'b1;
        end else begin
            borrow[0] = 1'b0;
        end
        temp_diff[0] = a[0] - b[0];
        
        // 第1位
        if (a[1] < (b[1] + borrow[0])) begin
            borrow[1] = 1'b1;
        end else begin
            borrow[1] = 1'b0;
        end
        temp_diff[1] = a[1] - b[1] - borrow[0];
        
        // 第2位
        if (a[2] < (b[2] + borrow[1])) begin
            borrow[2] = 1'b1;
        end else begin
            borrow[2] = 1'b0;
        end
        temp_diff[2] = a[2] - b[2] - borrow[1];
        
        // 第3位
        if (a[3] < (b[3] + borrow[2])) begin
            borrow[3] = 1'b1;
        end else begin
            borrow[3] = 1'b0;
        end
        temp_diff[3] = a[3] - b[3] - borrow[2];
    end
    
    assign diff = temp_diff;

endmodule