module hybrid_icmu (
    input clk, rst_n,
    input [15:0] maskable_int,
    input [3:0] unmaskable_int,
    input [15:0] mask,
    output reg [4:0] int_id,
    output reg int_valid,
    output reg unmaskable_active
);
    reg [15:0] masked_int;
    reg [19:0] combined_pending;
    reg processing = 1'b0;
    
    always @(*) begin
        masked_int = maskable_int & mask;
        combined_pending = {unmaskable_int, masked_int};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id <= 5'd0;
            int_valid <= 1'b0;
            unmaskable_active <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (!processing && |combined_pending) begin
                casez (combined_pending)
                    // Unmaskable first (highest priority)
                    20'b1???????????????????: begin
                        int_id <= 5'd19;
                        unmaskable_active <= 1'b1;
                    end
                    20'b01??????????????????: begin
                        int_id <= 5'd18;
                        unmaskable_active <= 1'b1;
                    end
                    20'b001?????????????????: begin
                        int_id <= 5'd17;
                        unmaskable_active <= 1'b1;
                    end
                    20'b0001????????????????: begin
                        int_id <= 5'd16;
                        unmaskable_active <= 1'b1;
                    end
                    // Then maskable
                    20'b00001???????????????: int_id <= 5'd15;
                    20'b000001??????????????: int_id <= 5'd14;
                    20'b0000001?????????????: int_id <= 5'd13;
                    20'b00000001????????????: int_id <= 5'd12;
                    20'b000000001???????????: int_id <= 5'd11;
                    20'b0000000001??????????: int_id <= 5'd10;
                    20'b00000000001?????????: int_id <= 5'd9;
                    20'b000000000001????????: int_id <= 5'd8;
                    20'b0000000000001???????: int_id <= 5'd7;
                    20'b00000000000001??????: int_id <= 5'd6;
                    20'b000000000000001?????: int_id <= 5'd5;
                    20'b0000000000000001????: int_id <= 5'd4;
                    20'b00000000000000001???: int_id <= 5'd3;
                    20'b000000000000000001??: int_id <= 5'd2;
                    20'b0000000000000000001?: int_id <= 5'd1;
                    20'b00000000000000000001: int_id <= 5'd0;
                    default: int_id <= 5'd0;
                endcase
                
                int_valid <= 1'b1;
                processing <= 1'b1;
            end else if (processing) begin
                int_valid <= 1'b0;
                unmaskable_active <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
endmodule