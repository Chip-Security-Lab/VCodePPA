//SystemVerilog
module sign_extension_shifter_valid_ready (
    input  wire         clk,
    input  wire         rst_n,
    // Valid-Ready handshake input interface
    input  wire [15:0]  in_data,
    input  wire [3:0]   in_shift_right,
    input  wire         in_sign_extend,
    input  wire         in_valid,
    output wire         in_ready,
    // Valid-Ready handshake output interface
    output wire [15:0]  out_data,
    output wire         out_valid,
    input  wire         out_ready
);

    // Internal registers for input data buffering
    reg  [15:0] input_data_reg;
    reg  [3:0]  shift_right_reg;
    reg         sign_extend_reg;
    reg         input_data_valid;
    wire        input_handshake;

    assign input_handshake = in_valid && in_ready;

    // Input ready: only accept new data when not holding unprocessed data
    assign in_ready = !input_data_valid || (output_handshake);

    // Capture input data on handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_data_reg  <= 16'b0;
            shift_right_reg <= 4'b0;
            sign_extend_reg <= 1'b0;
            input_data_valid <= 1'b0;
        end else begin
            // Accept new input if available and we are ready
            if (input_handshake) begin
                input_data_reg  <= in_data;
                shift_right_reg <= in_shift_right;
                sign_extend_reg <= in_sign_extend;
                input_data_valid <= 1'b1;
            end else if (output_handshake && input_data_valid) begin
                // Output consumed, clear local valid
                input_data_valid <= 1'b0;
            end
        end
    end

    // Output handshake logic
    assign out_valid = input_data_valid;
    wire output_handshake = out_valid && out_ready;

    // Compute sign bit
    wire sign_bit;
    assign sign_bit = input_data_reg[15];

    // Shifted logic
    reg [15:0] shifted;
    always @(*) begin
        case (shift_right_reg)
            4'd0:  shifted = input_data_reg;
            4'd1:  shifted = {1'b0, input_data_reg[15:1]};
            4'd2:  shifted = {2'b0, input_data_reg[15:2]};
            4'd3:  shifted = {3'b0, input_data_reg[15:3]};
            4'd4:  shifted = {4'b0, input_data_reg[15:4]};
            4'd5:  shifted = {5'b0, input_data_reg[15:5]};
            4'd6:  shifted = {6'b0, input_data_reg[15:6]};
            4'd7:  shifted = {7'b0, input_data_reg[15:7]};
            4'd8:  shifted = {8'b0, input_data_reg[15:8]};
            4'd9:  shifted = {9'b0, input_data_reg[15:9]};
            4'd10: shifted = {10'b0, input_data_reg[15:10]};
            4'd11: shifted = {11'b0, input_data_reg[15:11]};
            4'd12: shifted = {12'b0, input_data_reg[15:12]};
            4'd13: shifted = {13'b0, input_data_reg[15:13]};
            4'd14: shifted = {14'b0, input_data_reg[15:14]};
            4'd15: shifted = {15'b0, input_data_reg[15]};
            default: shifted = input_data_reg;
        endcase
    end

    // Sign-extended logic
    reg [15:0] sign_extended;
    always @(*) begin
        case (shift_right_reg)
            4'd0: sign_extended = input_data_reg;
            4'd1:  sign_extended = sign_bit ? {1'b1, input_data_reg[15:1]} : {1'b0, input_data_reg[15:1]};
            4'd2:  sign_extended = sign_bit ? {2'b11, input_data_reg[15:2]} : {2'b00, input_data_reg[15:2]};
            4'd3:  sign_extended = sign_bit ? {3'b111, input_data_reg[15:3]} : {3'b000, input_data_reg[15:3]};
            4'd4:  sign_extended = sign_bit ? {4'b1111, input_data_reg[15:4]} : {4'b0000, input_data_reg[15:4]};
            4'd5:  sign_extended = sign_bit ? {5'b11111, input_data_reg[15:5]} : {5'b00000, input_data_reg[15:5]};
            4'd6:  sign_extended = sign_bit ? {6'b111111, input_data_reg[15:6]} : {6'b000000, input_data_reg[15:6]};
            4'd7:  sign_extended = sign_bit ? {7'b1111111, input_data_reg[15:7]} : {7'b0000000, input_data_reg[15:7]};
            4'd8:  sign_extended = sign_bit ? {8'b11111111, input_data_reg[15:8]} : {8'b00000000, input_data_reg[15:8]};
            4'd9:  sign_extended = sign_bit ? {9'b111111111, input_data_reg[15:9]} : {9'b000000000, input_data_reg[15:9]};
            4'd10: sign_extended = sign_bit ? {10'b1111111111, input_data_reg[15:10]} : {10'b0000000000, input_data_reg[15:10]};
            4'd11: sign_extended = sign_bit ? {11'b11111111111, input_data_reg[15:11]} : {11'b00000000000, input_data_reg[15:11]};
            4'd12: sign_extended = sign_bit ? {12'b111111111111, input_data_reg[15:12]} : {12'b000000000000, input_data_reg[15:12]};
            4'd13: sign_extended = sign_bit ? {13'b1111111111111, input_data_reg[15:13]} : {13'b0000000000000, input_data_reg[15:13]};
            4'd14: sign_extended = sign_bit ? {14'b11111111111111, input_data_reg[15:14]} : {14'b00000000000000, input_data_reg[15:14]};
            4'd15: sign_extended = sign_bit ? {15'b111111111111111, input_data_reg[15]} : {15'b000000000000000, input_data_reg[15]};
            default: sign_extended = input_data_reg;
        endcase
    end

    // Output data register
    reg [15:0] output_data_reg;
    always @(*) begin
        if (sign_extend_reg)
            output_data_reg = sign_extended;
        else
            output_data_reg = shifted;
    end

    assign out_data = output_data_reg;

endmodule