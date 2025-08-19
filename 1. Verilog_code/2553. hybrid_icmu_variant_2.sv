//SystemVerilog
module hybrid_icmu (
    input clk, rst_n,
    input [15:0] maskable_int,
    input [3:0] unmaskable_int,
    input [15:0] mask,
    output reg [4:0] int_id,
    output reg int_valid,
    output reg unmaskable_active
);

    // Pipeline stage 1 registers
    reg [15:0] masked_int_stage1;
    reg [19:0] combined_pending_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [4:0] int_id_stage2;
    reg unmaskable_active_stage2;
    reg valid_stage2;
    
    // Pre-compute unmaskable active signals
    wire unmaskable_active_0 = |unmaskable_int[3:0];
    wire [15:0] masked_int = maskable_int & mask;
    wire [19:0] combined_pending = {unmaskable_int, masked_int};
    wire valid = |combined_pending;
    
    // Pipeline stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_int_stage1 <= 16'd0;
            combined_pending_stage1 <= 20'd0;
            valid_stage1 <= 1'b0;
        end else begin
            masked_int_stage1 <= masked_int;
            combined_pending_stage1 <= combined_pending;
            valid_stage1 <= valid;
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id_stage2 <= 5'd0;
            unmaskable_active_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                casez (combined_pending_stage1)
                    20'b1???????????????????: begin
                        int_id_stage2 <= 5'd19;
                        unmaskable_active_stage2 <= 1'b1;
                    end
                    20'b01??????????????????: begin
                        int_id_stage2 <= 5'd18;
                        unmaskable_active_stage2 <= 1'b1;
                    end
                    20'b001?????????????????: begin
                        int_id_stage2 <= 5'd17;
                        unmaskable_active_stage2 <= 1'b1;
                    end
                    20'b0001????????????????: begin
                        int_id_stage2 <= 5'd16;
                        unmaskable_active_stage2 <= 1'b1;
                    end
                    20'b00001???????????????: int_id_stage2 <= 5'd15;
                    20'b000001??????????????: int_id_stage2 <= 5'd14;
                    20'b0000001?????????????: int_id_stage2 <= 5'd13;
                    20'b00000001????????????: int_id_stage2 <= 5'd12;
                    20'b000000001???????????: int_id_stage2 <= 5'd11;
                    20'b0000000001??????????: int_id_stage2 <= 5'd10;
                    20'b00000000001?????????: int_id_stage2 <= 5'd9;
                    20'b000000000001????????: int_id_stage2 <= 5'd8;
                    20'b0000000000001???????: int_id_stage2 <= 5'd7;
                    20'b00000000000001??????: int_id_stage2 <= 5'd6;
                    20'b000000000000001?????: int_id_stage2 <= 5'd5;
                    20'b0000000000000001????: int_id_stage2 <= 5'd4;
                    20'b00000000000000001???: int_id_stage2 <= 5'd3;
                    20'b000000000000000001??: int_id_stage2 <= 5'd2;
                    20'b0000000000000000001?: int_id_stage2 <= 5'd1;
                    20'b00000000000000000001: int_id_stage2 <= 5'd0;
                    default: int_id_stage2 <= 5'd0;
                endcase
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
                unmaskable_active_stage2 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id <= 5'd0;
            int_valid <= 1'b0;
            unmaskable_active <= 1'b0;
        end else begin
            int_id <= int_id_stage2;
            int_valid <= valid_stage2;
            unmaskable_active <= unmaskable_active_stage2;
        end
    end

endmodule