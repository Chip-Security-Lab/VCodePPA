module ShiftSub(input [7:0] a, b, output reg [7:0] res);
    reg [7:0] borrow;
    reg [7:0] temp_res;
    
    always @(*) begin
        temp_res = a;
        borrow = 8'b0;
        
        // Bit 0
        if(temp_res[0] < b[0]) begin
            temp_res[0] = ~temp_res[0];
            borrow[1] = 1'b1;
        end else begin
            temp_res[0] = temp_res[0] - b[0];
        end
        
        // Bit 1
        if(temp_res[1] < (b[1] + borrow[1])) begin
            temp_res[1] = ~temp_res[1];
            borrow[2] = 1'b1;
        end else begin
            temp_res[1] = temp_res[1] - (b[1] + borrow[1]);
        end
        
        // Bit 2
        if(temp_res[2] < (b[2] + borrow[2])) begin
            temp_res[2] = ~temp_res[2];
            borrow[3] = 1'b1;
        end else begin
            temp_res[2] = temp_res[2] - (b[2] + borrow[2]);
        end
        
        // Bit 3
        if(temp_res[3] < (b[3] + borrow[3])) begin
            temp_res[3] = ~temp_res[3];
            borrow[4] = 1'b1;
        end else begin
            temp_res[3] = temp_res[3] - (b[3] + borrow[3]);
        end
        
        // Bit 4
        if(temp_res[4] < (b[4] + borrow[4])) begin
            temp_res[4] = ~temp_res[4];
            borrow[5] = 1'b1;
        end else begin
            temp_res[4] = temp_res[4] - (b[4] + borrow[4]);
        end
        
        // Bit 5
        if(temp_res[5] < (b[5] + borrow[5])) begin
            temp_res[5] = ~temp_res[5];
            borrow[6] = 1'b1;
        end else begin
            temp_res[5] = temp_res[5] - (b[5] + borrow[5]);
        end
        
        // Bit 6
        if(temp_res[6] < (b[6] + borrow[6])) begin
            temp_res[6] = ~temp_res[6];
            borrow[7] = 1'b1;
        end else begin
            temp_res[6] = temp_res[6] - (b[6] + borrow[6]);
        end
        
        // Bit 7
        if(temp_res[7] < (b[7] + borrow[7])) begin
            temp_res[7] = ~temp_res[7];
        end else begin
            temp_res[7] = temp_res[7] - (b[7] + borrow[7]);
        end
        
        res = temp_res;
    end
endmodule