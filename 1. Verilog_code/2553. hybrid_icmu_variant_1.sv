//SystemVerilog
module hybrid_icmu_axi_stream (
    input clk,
    input rst_n,
    input [15:0] maskable_int,
    input [3:0] unmaskable_int,
    input [15:0] mask,
    output reg [15:0] tdata,
    output reg tvalid,
    input tready,
    output reg tlast
);
    reg [15:0] masked_int;
    reg [19:0] combined_pending;
    reg processing = 1'b0;
    reg [4:0] int_id;
    reg unmaskable_active;
    
    wire [19:0] priority_encoder;
    wire [4:0] encoded_id;
    
    always @(*) begin
        masked_int = maskable_int & mask;
        combined_pending = {unmaskable_int, masked_int};
    end
    
    // Priority encoder implementation
    assign priority_encoder[0] = combined_pending[0];
    assign priority_encoder[1] = combined_pending[1] & ~combined_pending[0];
    assign priority_encoder[2] = combined_pending[2] & ~(|combined_pending[1:0]);
    assign priority_encoder[3] = combined_pending[3] & ~(|combined_pending[2:0]);
    assign priority_encoder[4] = combined_pending[4] & ~(|combined_pending[3:0]);
    assign priority_encoder[5] = combined_pending[5] & ~(|combined_pending[4:0]);
    assign priority_encoder[6] = combined_pending[6] & ~(|combined_pending[5:0]);
    assign priority_encoder[7] = combined_pending[7] & ~(|combined_pending[6:0]);
    assign priority_encoder[8] = combined_pending[8] & ~(|combined_pending[7:0]);
    assign priority_encoder[9] = combined_pending[9] & ~(|combined_pending[8:0]);
    assign priority_encoder[10] = combined_pending[10] & ~(|combined_pending[9:0]);
    assign priority_encoder[11] = combined_pending[11] & ~(|combined_pending[10:0]);
    assign priority_encoder[12] = combined_pending[12] & ~(|combined_pending[11:0]);
    assign priority_encoder[13] = combined_pending[13] & ~(|combined_pending[12:0]);
    assign priority_encoder[14] = combined_pending[14] & ~(|combined_pending[13:0]);
    assign priority_encoder[15] = combined_pending[15] & ~(|combined_pending[14:0]);
    assign priority_encoder[16] = combined_pending[16] & ~(|combined_pending[15:0]);
    assign priority_encoder[17] = combined_pending[17] & ~(|combined_pending[16:0]);
    assign priority_encoder[18] = combined_pending[18] & ~(|combined_pending[17:0]);
    assign priority_encoder[19] = combined_pending[19] & ~(|combined_pending[18:0]);

    // Binary encoder
    assign encoded_id = priority_encoder[0] ? 5'd0 :
                       priority_encoder[1] ? 5'd1 :
                       priority_encoder[2] ? 5'd2 :
                       priority_encoder[3] ? 5'd3 :
                       priority_encoder[4] ? 5'd4 :
                       priority_encoder[5] ? 5'd5 :
                       priority_encoder[6] ? 5'd6 :
                       priority_encoder[7] ? 5'd7 :
                       priority_encoder[8] ? 5'd8 :
                       priority_encoder[9] ? 5'd9 :
                       priority_encoder[10] ? 5'd10 :
                       priority_encoder[11] ? 5'd11 :
                       priority_encoder[12] ? 5'd12 :
                       priority_encoder[13] ? 5'd13 :
                       priority_encoder[14] ? 5'd14 :
                       priority_encoder[15] ? 5'd15 :
                       priority_encoder[16] ? 5'd16 :
                       priority_encoder[17] ? 5'd17 :
                       priority_encoder[18] ? 5'd18 :
                       priority_encoder[19] ? 5'd19 : 5'd0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id <= 5'd0;
            tvalid <= 1'b0;
            tlast <= 1'b0;
            unmaskable_active <= 1'b0;
            processing <= 1'b0;
            tdata <= 16'd0;
        end else begin
            if (!processing && |combined_pending) begin
                int_id <= encoded_id;
                unmaskable_active <= |combined_pending[19:16];
                tdata <= {11'd0, encoded_id};
                tvalid <= 1'b1;
                tlast <= 1'b1;
                processing <= 1'b1;
            end else if (processing && tready) begin
                tvalid <= 1'b0;
                tlast <= 1'b0;
                unmaskable_active <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
endmodule