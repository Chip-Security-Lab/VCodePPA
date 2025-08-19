//SystemVerilog
module i2c_multimaster(
    input  wire        clock,
    input  wire        resetn,
    input  wire        start_cmd,
    input  wire [6:0]  s_address,
    input  wire [7:0]  write_data,
    input  wire        read_request,
    output reg  [7:0]  read_data,
    output reg         busy,
    output reg         arbitration_lost,
    inout              scl,
    inout              sda
);

    // Pipeline stage registers
    reg                sda_drive_stage1, sda_drive_stage2, sda_drive_stage3;
    reg                scl_drive_stage1, scl_drive_stage2, scl_drive_stage3;
    reg  [3:0]         state_stage1, state_stage2, state_stage3, state_stage4;
    reg  [3:0]         bit_pos_stage1, bit_pos_stage2, bit_pos_stage3, bit_pos_stage4;
    reg                sda_sensed_stage1, sda_sensed_stage2, sda_sensed_stage3;
    reg                start_cmd_stage1, start_cmd_stage2, start_cmd_stage3;
    reg  [6:0]         s_address_stage1, s_address_stage2, s_address_stage3;
    reg  [7:0]         write_data_stage1, write_data_stage2, write_data_stage3;
    reg                read_request_stage1, read_request_stage2, read_request_stage3;
    reg  [7:0]         read_data_stage1, read_data_stage2, read_data_stage3;

    // Output drive
    assign sda = sda_drive_stage3 ? 1'b0 : 1'bz;
    assign scl = scl_drive_stage3 ? 1'b0 : 1'bz;

    // Sensing sda at input for pipeline
    wire sda_sensed_now = sda;

    // Busy indicator pipeline
    reg busy_stage1, busy_stage2, busy_stage3, busy_stage4;

    // Arbitration lost pipeline
    reg arbitration_lost_stage1, arbitration_lost_stage2, arbitration_lost_stage3;

    // Pipeline register stage 1: input sampling and initial state
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            sda_drive_stage1         <= 1'b0;
            scl_drive_stage1         <= 1'b0;
            state_stage1             <= 4'd0;
            bit_pos_stage1           <= 4'd0;
            sda_sensed_stage1        <= 1'b1;
            start_cmd_stage1         <= 1'b0;
            s_address_stage1         <= 7'd0;
            write_data_stage1        <= 8'd0;
            read_request_stage1      <= 1'b0;
            read_data_stage1         <= 8'd0;
            busy_stage1              <= 1'b0;
            arbitration_lost_stage1  <= 1'b0;
        end else begin
            // Sample inputs and current state
            sda_drive_stage1         <= sda_drive_stage3;
            scl_drive_stage1         <= scl_drive_stage3;
            state_stage1             <= state_stage4;
            bit_pos_stage1           <= bit_pos_stage4;
            sda_sensed_stage1        <= sda_sensed_now;
            start_cmd_stage1         <= start_cmd;
            s_address_stage1         <= s_address;
            write_data_stage1        <= write_data;
            read_request_stage1      <= read_request;
            read_data_stage1         <= read_data_stage3;
            busy_stage1              <= busy_stage4;
            arbitration_lost_stage1  <= arbitration_lost_stage3;
        end
    end

    // Pipeline register stage 2: propagate signals
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            sda_drive_stage2         <= 1'b0;
            scl_drive_stage2         <= 1'b0;
            state_stage2             <= 4'd0;
            bit_pos_stage2           <= 4'd0;
            sda_sensed_stage2        <= 1'b1;
            start_cmd_stage2         <= 1'b0;
            s_address_stage2         <= 7'd0;
            write_data_stage2        <= 8'd0;
            read_request_stage2      <= 1'b0;
            read_data_stage2         <= 8'd0;
            busy_stage2              <= 1'b0;
            arbitration_lost_stage2  <= 1'b0;
        end else begin
            sda_drive_stage2         <= sda_drive_stage1;
            scl_drive_stage2         <= scl_drive_stage1;
            state_stage2             <= state_stage1;
            bit_pos_stage2           <= bit_pos_stage1;
            sda_sensed_stage2        <= sda_sensed_stage1;
            start_cmd_stage2         <= start_cmd_stage1;
            s_address_stage2         <= s_address_stage1;
            write_data_stage2        <= write_data_stage1;
            read_request_stage2      <= read_request_stage1;
            read_data_stage2         <= read_data_stage1;
            busy_stage2              <= busy_stage1;
            arbitration_lost_stage2  <= arbitration_lost_stage1;
        end
    end

    // Pipeline register stage 3: combinational logic split and drive signals
    reg sda_drive_longpath_reg, scl_drive_longpath_reg;
    reg [3:0] state_longpath_reg, bit_pos_longpath_reg;
    reg sda_sensed_longpath_reg;
    reg start_cmd_longpath_reg;
    reg [6:0] s_address_longpath_reg;
    reg [7:0] write_data_longpath_reg;
    reg read_request_longpath_reg;
    reg [7:0] read_data_longpath_reg;
    reg busy_longpath_reg;
    reg arbitration_lost_longpath_reg;

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            sda_drive_longpath_reg         <= 1'b0;
            scl_drive_longpath_reg         <= 1'b0;
            state_longpath_reg             <= 4'd0;
            bit_pos_longpath_reg           <= 4'd0;
            sda_sensed_longpath_reg        <= 1'b1;
            start_cmd_longpath_reg         <= 1'b0;
            s_address_longpath_reg         <= 7'd0;
            write_data_longpath_reg        <= 8'd0;
            read_request_longpath_reg      <= 1'b0;
            read_data_longpath_reg         <= 8'd0;
            busy_longpath_reg              <= 1'b0;
            arbitration_lost_longpath_reg  <= 1'b0;
        end else begin
            // Inserted pipeline cut here for long combinational path
            sda_drive_longpath_reg         <= sda_drive_stage2;
            scl_drive_longpath_reg         <= scl_drive_stage2;
            state_longpath_reg             <= state_stage2;
            bit_pos_longpath_reg           <= bit_pos_stage2;
            sda_sensed_longpath_reg        <= sda_sensed_stage2;
            start_cmd_longpath_reg         <= start_cmd_stage2;
            s_address_longpath_reg         <= s_address_stage2;
            write_data_longpath_reg        <= write_data_stage2;
            read_request_longpath_reg      <= read_request_stage2;
            read_data_longpath_reg         <= read_data_stage2;
            busy_longpath_reg              <= busy_stage2;
            arbitration_lost_longpath_reg  <= arbitration_lost_stage2;
        end
    end

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            sda_drive_stage3         <= 1'b0;
            scl_drive_stage3         <= 1'b0;
            state_stage3             <= 4'd0;
            bit_pos_stage3           <= 4'd0;
            sda_sensed_stage3        <= 1'b1;
            start_cmd_stage3         <= 1'b0;
            s_address_stage3         <= 7'd0;
            write_data_stage3        <= 8'd0;
            read_request_stage3      <= 1'b0;
            read_data_stage3         <= 8'd0;
            busy_stage3              <= 1'b0;
            arbitration_lost_stage3  <= 1'b0;
        end else begin
            sda_drive_stage3         <= sda_drive_longpath_reg;
            scl_drive_stage3         <= scl_drive_longpath_reg;
            state_stage3             <= state_longpath_reg;
            bit_pos_stage3           <= bit_pos_longpath_reg;
            sda_sensed_stage3        <= sda_sensed_longpath_reg;
            start_cmd_stage3         <= start_cmd_longpath_reg;
            s_address_stage3         <= s_address_longpath_reg;
            write_data_stage3        <= write_data_longpath_reg;
            read_request_stage3      <= read_request_longpath_reg;
            read_data_stage3         <= read_data_longpath_reg;
            busy_stage3              <= busy_longpath_reg;
            arbitration_lost_stage3  <= arbitration_lost_longpath_reg;
        end
    end

    // Pipeline register stage 4: arbitration and control
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            arbitration_lost         <= 1'b0;
            state_stage4             <= 4'd0;
            bit_pos_stage4           <= 4'd0;
            busy_stage4              <= 1'b0;
        end else begin
            // Arbitration lost logic
            if (state_stage3 != 4'd0 && sda_drive_stage3 && !sda_sensed_stage3) begin
                arbitration_lost     <= 1'b1;
                state_stage4         <= 4'd0;
                busy_stage4          <= 1'b0;
            end else begin
                arbitration_lost     <= arbitration_lost_stage3;
                state_stage4         <= state_stage3;
                busy_stage4          <= busy_stage3;
            end
            bit_pos_stage4           <= bit_pos_stage3;
        end
    end

    // Output assignments
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            busy <= 1'b0;
            read_data <= 8'd0;
        end else begin
            busy <= busy_stage4;
            read_data <= read_data_stage3;
        end
    end

endmodule