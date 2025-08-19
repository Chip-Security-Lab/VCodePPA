//SystemVerilog
module asr_shift_axi_stream (
    input               clk,
    input               rst,
    // AXI-Stream Slave Interface (Input)
    input       [7:0]   s_axis_tdata,
    input               s_axis_tvalid,
    output              s_axis_tready,
    input       [2:0]   s_axis_shift,
    // AXI-Stream Master Interface (Output)
    output reg  [7:0]   m_axis_tdata,
    output reg          m_axis_tvalid,
    input               m_axis_tready,
    output reg          m_axis_tlast
);

    // Internal buffering for AXI-Stream handshake
    reg  [7:0]  data_buf1;
    reg  [7:0]  data_buf2;
    reg  [2:0]  shift_buf1;
    reg  [2:0]  shift_buf2;
    reg         valid_buf1;
    reg         valid_buf2;
    reg         tready_int;

    // AXI-Stream input handshake
    assign s_axis_tready = tready_int;

    // Input buffer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buf1   <= 8'b0;
            shift_buf1  <= 3'b0;
            valid_buf1  <= 1'b0;
        end else if (tready_int) begin
            data_buf1   <= s_axis_tdata;
            shift_buf1  <= s_axis_shift;
            valid_buf1  <= s_axis_tvalid;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buf2   <= 8'b0;
            shift_buf2  <= 3'b0;
            valid_buf2  <= 1'b0;
        end else begin
            data_buf2   <= data_buf1;
            shift_buf2  <= shift_buf1;
            valid_buf2  <= valid_buf1;
        end
    end

    // 8-bit borrow subtractor function
    function [7:0] borrow_subtractor_8bit;
        input [7:0] minuend;
        input [7:0] subtrahend;
        reg [7:0] difference;
        reg [7:0] borrow;
        integer i;
        begin
            borrow[0] = 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
                if (i < 7)
                    borrow[i+1] = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow[i]);
            end
            borrow_subtractor_8bit = difference;
        end
    endfunction

    reg [7:0] shift_mask;
    reg [7:0] arithmetic_mask;
    reg [7:0] right_shifted;
    reg [7:0] sign_extend_mask;
    reg [7:0] subtraction_result;
    reg [7:0] data_result;
    reg       data_valid;

    // Combinational ASR calculation
    always @(*) begin
        shift_mask         = 8'hFF >> shift_buf2;
        sign_extend_mask   = ~shift_mask;
        right_shifted      = data_buf2 >> shift_buf2;
        arithmetic_mask    = data_buf2[7] ? sign_extend_mask : 8'b0;
        subtraction_result = borrow_subtractor_8bit(right_shifted, ~arithmetic_mask);
        data_result        = subtraction_result + arithmetic_mask;
        data_valid         = valid_buf2;
    end

    // AXI-Stream output handshake and data register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata  <= 8'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            if (data_valid && (!m_axis_tvalid || m_axis_tready)) begin
                m_axis_tdata  <= data_result;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b1; // Single transfer per handshake
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

    // AXI-Stream ready logic
    always @(*) begin
        tready_int = (!valid_buf1) || (valid_buf1 && (!m_axis_tvalid || m_axis_tready));
    end

endmodule