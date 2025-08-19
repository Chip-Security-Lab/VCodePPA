//SystemVerilog
module hybrid_icmu_axi_stream (
    input clk, rst_n,
    // AXI-Stream Slave Interface
    input [15:0] s_axis_tdata,      // maskable_int
    input [3:0] s_axis_tuser,       // unmaskable_int
    input s_axis_tvalid,
    output reg s_axis_tready,
    // AXI-Stream Master Interface
    output reg [15:0] m_axis_tdata,  // int_id + unmaskable_active
    output reg m_axis_tvalid,
    input m_axis_tready,
    // Control Interface
    input [15:0] mask
);

    // Pipeline stage 1 registers
    reg [15:0] masked_int_stage1;
    reg [19:0] combined_pending_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [4:0] int_id_stage2;
    reg unmaskable_active_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_int_stage1 <= 16'd0;
            combined_pending_stage1 <= 20'd0;
            valid_stage1 <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            masked_int_stage1 <= s_axis_tdata & mask;
            combined_pending_stage1 <= {s_axis_tuser, masked_int_stage1};
            valid_stage1 <= |{s_axis_tuser, s_axis_tdata};
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id_stage2 <= 5'd0;
            unmaskable_active_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
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
    
    // AXI-Stream handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 16'd0;
        end else begin
            s_axis_tready <= !valid_stage1 || (valid_stage2 && m_axis_tready);
            m_axis_tvalid <= valid_stage2;
            m_axis_tdata <= {11'b0, int_id_stage2, unmaskable_active_stage2};
        end
    end

endmodule