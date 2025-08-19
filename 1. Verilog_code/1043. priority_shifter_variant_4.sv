//SystemVerilog
module priority_shifter_valid_ready (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [15:0]  in_data,
    input  wire [15:0]  priority_mask,
    input  wire         in_valid,
    output wire         in_ready,
    output wire [15:0]  out_data,
    output wire         out_valid,
    input  wire         out_ready
);

    // Internal registers for handshake and data buffering
    reg [15:0] in_data_reg;
    reg [15:0] priority_mask_reg;
    reg        data_buffer_full;
    reg [15:0] out_data_reg;
    reg        out_valid_reg;

    // Handshake logic
    assign in_ready  = ~data_buffer_full;
    assign out_data  = out_data_reg;
    assign out_valid = out_valid_reg;

    // Buffer data on handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_reg        <= 16'd0;
            priority_mask_reg  <= 16'd0;
            data_buffer_full   <= 1'b0;
        end else if (in_valid && in_ready) begin
            in_data_reg        <= in_data;
            priority_mask_reg  <= priority_mask;
            data_buffer_full   <= 1'b1;
        end else if (out_valid && out_ready) begin
            data_buffer_full   <= 1'b0;
        end
    end

    // Priority encoder: find highest priority
    reg [3:0] highest_priority;
    always @(*) begin
        casex (priority_mask_reg)
            16'b1xxxxxxxxxxxxxxx: highest_priority = 4'd15;
            16'b01xxxxxxxxxxxxxx: highest_priority = 4'd14;
            16'b001xxxxxxxxxxxxx: highest_priority = 4'd13;
            16'b0001xxxxxxxxxxxx: highest_priority = 4'd12;
            16'b00001xxxxxxxxxxx: highest_priority = 4'd11;
            16'b000001xxxxxxxxxx: highest_priority = 4'd10;
            16'b0000001xxxxxxxxx: highest_priority = 4'd9;
            16'b00000001xxxxxxxx: highest_priority = 4'd8;
            16'b000000001xxxxxxx: highest_priority = 4'd7;
            16'b0000000001xxxxxx: highest_priority = 4'd6;
            16'b00000000001xxxxx: highest_priority = 4'd5;
            16'b000000000001xxxx: highest_priority = 4'd4;
            16'b0000000000001xxx: highest_priority = 4'd3;
            16'b00000000000001xx: highest_priority = 4'd2;
            16'b000000000000001x: highest_priority = 4'd1;
            16'b0000000000000001: highest_priority = 4'd0;
            default: highest_priority = 4'd0;
        endcase
    end

    // Barrel shifter structure
    wire [15:0] shift_stage_0;
    wire [15:0] shift_stage_1;
    wire [15:0] shift_stage_2;
    wire [15:0] shift_stage_3;

    // First stage: shift by 4
    assign shift_stage_0 = highest_priority[3] ? {in_data_reg[11:0], 4'b0} : in_data_reg;
    // Second stage: shift by 8
    assign shift_stage_1 = highest_priority[2] ? {shift_stage_0[7:0], 8'b0} : shift_stage_0;
    // Third stage: shift by 2
    assign shift_stage_2 = highest_priority[1] ? {shift_stage_1[13:0], 2'b0} : shift_stage_1;
    // Fourth stage: shift by 1
    assign shift_stage_3 = highest_priority[0] ? {shift_stage_2[14:0], 1'b0} : shift_stage_2;

    // Output register with handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data_reg  <= 16'd0;
            out_valid_reg <= 1'b0;
        end else if (data_buffer_full && (!out_valid_reg || (out_valid_reg && out_ready))) begin
            out_data_reg  <= shift_stage_3;
            out_valid_reg <= 1'b1;
        end else if (out_valid_reg && out_ready) begin
            out_valid_reg <= 1'b0;
        end
    end

endmodule