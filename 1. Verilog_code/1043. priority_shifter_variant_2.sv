//SystemVerilog
module priority_shifter_axi_stream (
    input              clk,
    input              rst_n,

    // AXI-Stream Slave (input) interface for in_data and priority_mask
    input      [15:0]  s_axis_tdata,         // [15:0]  in_data
    input      [15:0]  s_axis_tpriority,     // [15:0]  priority_mask
    input              s_axis_tvalid,
    output             s_axis_tready,
    input              s_axis_tlast,         // Optional, can be tied if unused

    // AXI-Stream Master (output) interface for out_data
    output     [15:0]  m_axis_tdata,         // [15:0]  out_data
    output             m_axis_tvalid,
    input              m_axis_tready,
    output             m_axis_tlast          // Optional, can be tied if unused
);

    // Internal registers for data handshake and pipeline
    reg        [15:0]  reg_in_data;
    reg        [15:0]  reg_priority_mask;
    reg                reg_input_valid;
    reg                reg_input_last;

    wire               input_handshake;
    wire               output_handshake;

    assign input_handshake  = s_axis_tvalid && s_axis_tready;
    assign output_handshake = reg_input_valid && m_axis_tready;

    // Input handshake logic
    assign s_axis_tready = !reg_input_valid || (output_handshake);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_in_data       <= 16'd0;
            reg_priority_mask <= 16'd0;
            reg_input_valid   <= 1'b0;
            reg_input_last    <= 1'b0;
        end else begin
            if (input_handshake) begin
                reg_in_data       <= s_axis_tdata;
                reg_priority_mask <= s_axis_tpriority;
                reg_input_valid   <= 1'b1;
                reg_input_last    <= s_axis_tlast;
            end else if (output_handshake) begin
                reg_input_valid   <= 1'b0;
            end
        end
    end

    // Priority encoder
    reg [3:0] highest_priority;
    always @(*) begin
        casex (reg_priority_mask)
            16'b1??????????????? : highest_priority = 4'd15;
            16'b01?????????????? : highest_priority = 4'd14;
            16'b001????????????? : highest_priority = 4'd13;
            16'b0001???????????? : highest_priority = 4'd12;
            16'b00001??????????? : highest_priority = 4'd11;
            16'b000001?????????? : highest_priority = 4'd10;
            16'b0000001????????? : highest_priority = 4'd9;
            16'b00000001???????? : highest_priority = 4'd8;
            16'b000000001??????? : highest_priority = 4'd7;
            16'b0000000001?????? : highest_priority = 4'd6;
            16'b00000000001????? : highest_priority = 4'd5;
            16'b000000000001???? : highest_priority = 4'd4;
            16'b0000000000001??? : highest_priority = 4'd3;
            16'b00000000000001?? : highest_priority = 4'd2;
            16'b000000000000001? : highest_priority = 4'd1;
            16'b0000000000000001 : highest_priority = 4'd0;
            default              : highest_priority = 4'd0;
        endcase
    end

    // Shifted data calculation
    reg [15:0] shifted_data;
    always @(*) begin
        case (highest_priority)
            4'd0:  shifted_data = reg_in_data << 0;
            4'd1:  shifted_data = reg_in_data << 1;
            4'd2:  shifted_data = reg_in_data << 2;
            4'd3:  shifted_data = reg_in_data << 3;
            4'd4:  shifted_data = reg_in_data << 4;
            4'd5:  shifted_data = reg_in_data << 5;
            4'd6:  shifted_data = reg_in_data << 6;
            4'd7:  shifted_data = reg_in_data << 7;
            4'd8:  shifted_data = reg_in_data << 8;
            4'd9:  shifted_data = reg_in_data << 9;
            4'd10: shifted_data = reg_in_data << 10;
            4'd11: shifted_data = reg_in_data << 11;
            4'd12: shifted_data = reg_in_data << 12;
            4'd13: shifted_data = reg_in_data << 13;
            4'd14: shifted_data = reg_in_data << 14;
            4'd15: shifted_data = reg_in_data << 15;
            default: shifted_data = reg_in_data;
        endcase
    end

    // Output AXI-Stream signals
    assign m_axis_tdata  = shifted_data;
    assign m_axis_tvalid = reg_input_valid;
    assign m_axis_tlast  = reg_input_last;

endmodule