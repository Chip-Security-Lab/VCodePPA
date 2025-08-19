//SystemVerilog
`timescale 1ns / 1ps

module axi_stream_var_rotation_shifter (
    input               clk,
    input               rst_n,
    // AXI-Stream Slave Interface (Input)
    input       [7:0]   s_axis_tdata,
    input       [2:0]   s_axis_trot_amt,
    input               s_axis_trot_dir, // 0=left, 1=right
    input               s_axis_tvalid,
    output reg          s_axis_tready,
    // AXI-Stream Master Interface (Output)
    output reg  [7:0]   m_axis_tdata,
    output reg          m_axis_tvalid,
    input               m_axis_tready,
    output reg          m_axis_tlast
);

    // Forward retiming: move input-side registers after the rotation logic
    reg        input_latched;
    reg [7:0]  rot_input_data;
    reg [2:0]  rot_input_amt;
    reg        rot_input_dir;

    wire [7:0] right_rotated_w;
    wire [7:0] left_rotated_w;

    reg        output_reg_valid;
    reg [7:0]  output_reg_data;
    reg        output_reg_last;
    reg        processing_done_reg;
    reg        ready_d;

    // AXI-Stream handshake for input, now only ready/valid latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready   <= 1'b1;
            input_latched   <= 1'b0;
            rot_input_data  <= 8'b0;
            rot_input_amt   <= 3'b0;
            rot_input_dir   <= 1'b0;
        end else begin
            if (s_axis_tready && s_axis_tvalid) begin
                rot_input_data <= s_axis_tdata;
                rot_input_amt  <= s_axis_trot_amt;
                rot_input_dir  <= s_axis_trot_dir;
                input_latched  <= 1'b1;
                s_axis_tready  <= 1'b0;
            end else if (processing_done_reg && m_axis_tready) begin
                s_axis_tready  <= 1'b1;
                input_latched  <= 1'b0;
            end
        end
    end

    // Combinational rotation logic (moved before retiming registers)
    assign right_rotated_w = (rot_input_amt == 3'd0) ? rot_input_data :
                             (rot_input_amt == 3'd1) ? {rot_input_data[0], rot_input_data[7:1]} :
                             (rot_input_amt == 3'd2) ? {rot_input_data[1:0], rot_input_data[7:2]} :
                             (rot_input_amt == 3'd3) ? {rot_input_data[2:0], rot_input_data[7:3]} :
                             (rot_input_amt == 3'd4) ? {rot_input_data[3:0], rot_input_data[7:4]} :
                             (rot_input_amt == 3'd5) ? {rot_input_data[4:0], rot_input_data[7:5]} :
                             (rot_input_amt == 3'd6) ? {rot_input_data[5:0], rot_input_data[7:6]} :
                             (rot_input_amt == 3'd7) ? {rot_input_data[6:0], rot_input_data[7]}  :
                                                       rot_input_data;

    assign left_rotated_w  = (rot_input_amt == 3'd0) ? rot_input_data :
                             (rot_input_amt == 3'd1) ? {rot_input_data[6:0], rot_input_data[7]} :
                             (rot_input_amt == 3'd2) ? {rot_input_data[5:0], rot_input_data[7:6]} :
                             (rot_input_amt == 3'd3) ? {rot_input_data[4:0], rot_input_data[7:5]} :
                             (rot_input_amt == 3'd4) ? {rot_input_data[3:0], rot_input_data[7:4]} :
                             (rot_input_amt == 3'd5) ? {rot_input_data[2:0], rot_input_data[7:3]} :
                             (rot_input_amt == 3'd6) ? {rot_input_data[1:0], rot_input_data[7:2]} :
                             (rot_input_amt == 3'd7) ? {rot_input_data[0], rot_input_data[7:1]}  :
                                                       rot_input_data;

    // Output registers (retimed to after rotation logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_reg_data    <= 8'b0;
            output_reg_valid   <= 1'b0;
            output_reg_last    <= 1'b0;
            processing_done_reg<= 1'b0;
        end else begin
            if (input_latched && !output_reg_valid) begin
                if (rot_input_dir) // Right rotation
                    output_reg_data <= right_rotated_w;
                else
                    output_reg_data <= left_rotated_w;
                output_reg_valid   <= 1'b1;
                output_reg_last    <= 1'b1;
                processing_done_reg<= 1'b1;
            end else if (output_reg_valid && m_axis_tready) begin
                output_reg_valid   <= 1'b0;
                output_reg_last    <= 1'b0;
                processing_done_reg<= 1'b0;
            end
        end
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata   <= 8'b0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;
        end else begin
            m_axis_tdata   <= output_reg_data;
            m_axis_tvalid  <= output_reg_valid;
            m_axis_tlast   <= output_reg_last;
        end
    end

endmodule