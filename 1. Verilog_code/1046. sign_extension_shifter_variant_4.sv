//SystemVerilog
module sign_extension_shifter_valid_ready (
    input  wire         clk,
    input  wire         rst_n,

    // Valid-Ready handshake input
    input  wire [15:0]  in_data,
    input  wire [3:0]   in_shift_right,
    input  wire         in_sign_extend,
    input  wire         in_valid,
    output wire         in_ready,

    // Valid-Ready handshake output
    output wire [15:0]  out_data,
    output wire         out_valid,
    input  wire         out_ready
);

    // Input register handshake
    reg [15:0]  input_data_reg;
    reg [3:0]   shift_right_reg;
    reg         sign_extend_reg;
    reg         input_valid_reg;
    wire        input_handshake;

    assign input_handshake = in_valid && in_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_data_reg   <= 16'b0;
            shift_right_reg  <= 4'b0;
            sign_extend_reg  <= 1'b0;
            input_valid_reg  <= 1'b0;
        end else if (input_handshake) begin
            input_data_reg   <= in_data;
            shift_right_reg  <= in_shift_right;
            sign_extend_reg  <= in_sign_extend;
            input_valid_reg  <= 1'b1;
        end else if (out_valid && out_ready) begin
            input_valid_reg  <= 1'b0;
        end
    end

    assign in_ready = (!input_valid_reg) || (out_valid && out_ready);

    // Output register handshake
    reg [15:0]  result_reg;
    reg         result_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg       <= 16'b0;
            result_valid_reg <= 1'b0;
        end else begin
            if (input_valid_reg && (!result_valid_reg || (out_valid && out_ready))) begin
                result_reg       <= compute_result(input_data_reg, shift_right_reg, sign_extend_reg);
                result_valid_reg <= 1'b1;
            end else if (out_valid && out_ready) begin
                result_valid_reg <= 1'b0;
            end
        end
    end

    assign out_data  = result_reg;
    assign out_valid = result_valid_reg;

    // Function to compute result based on sign_extend
    function [15:0] compute_result;
        input [15:0] data;
        input [3:0]  shift_amt;
        input        sign_ext;
        reg   [15:0] shifted_val;
        reg   [15:0] sign_ext_val;
        reg          sign_bit;
        begin
            sign_bit = data[15];
            // Logical right shift
            case (shift_amt)
                4'd0:  shifted_val = data;
                4'd1:  shifted_val = {1'b0, data[15:1]};
                4'd2:  shifted_val = {2'b0, data[15:2]};
                4'd3:  shifted_val = {3'b0, data[15:3]};
                4'd4:  shifted_val = {4'b0, data[15:4]};
                4'd5:  shifted_val = {5'b0, data[15:5]};
                4'd6:  shifted_val = {6'b0, data[15:6]};
                4'd7:  shifted_val = {7'b0, data[15:7]};
                4'd8:  shifted_val = {8'b0, data[15:8]};
                4'd9:  shifted_val = {9'b0, data[15:9]};
                4'd10: shifted_val = {10'b0, data[15:10]};
                4'd11: shifted_val = {11'b0, data[15:11]};
                4'd12: shifted_val = {12'b0, data[15:12]};
                4'd13: shifted_val = {13'b0, data[15:13]};
                4'd14: shifted_val = {14'b0, data[15:14]};
                4'd15: shifted_val = {15'b0, data[15]};
                default: shifted_val = data;
            endcase
            // Sign extension right shift
            case (shift_amt)
                4'd0: sign_ext_val = data;
                4'd1: sign_ext_val = { {1{sign_bit}}, data[15:1] };
                4'd2: sign_ext_val = { {2{sign_bit}}, data[15:2] };
                4'd3: sign_ext_val = { {3{sign_bit}}, data[15:3] };
                4'd4: sign_ext_val = { {4{sign_bit}}, data[15:4] };
                4'd5: sign_ext_val = { {5{sign_bit}}, data[15:5] };
                4'd6: sign_ext_val = { {6{sign_bit}}, data[15:6] };
                4'd7: sign_ext_val = { {7{sign_bit}}, data[15:7] };
                4'd8: sign_ext_val = { {8{sign_bit}}, data[15:8] };
                4'd9: sign_ext_val = { {9{sign_bit}}, data[15:9] };
                4'd10: sign_ext_val = { {10{sign_bit}}, data[15:10] };
                4'd11: sign_ext_val = { {11{sign_bit}}, data[15:11] };
                4'd12: sign_ext_val = { {12{sign_bit}}, data[15:12] };
                4'd13: sign_ext_val = { {13{sign_bit}}, data[15:13] };
                4'd14: sign_ext_val = { {14{sign_bit}}, data[15:14] };
                4'd15: sign_ext_val = { {15{sign_bit}}, data[15] };
                default: sign_ext_val = data;
            endcase
            if (sign_ext)
                compute_result = sign_ext_val;
            else
                compute_result = shifted_val;
        end
    endfunction

endmodule