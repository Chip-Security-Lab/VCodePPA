//SystemVerilog
module i2c_multimaster(
    input clock, resetn,
    input start_cmd,
    input [6:0] s_address,
    input [7:0] write_data,
    input read_request,
    output [7:0] read_data,
    output busy, arbitration_lost,
    inout scl, sda
);
    reg sda_drive_reg, scl_drive_reg;
    reg [3:0] state_reg;
    reg [3:0] bit_pos_reg;

    // Retimed output registers: move them backward, before combinational logic
    reg [7:0] read_data_reg;
    reg busy_reg, arbitration_lost_reg;

    // New registers to hold output values before combinational logic
    reg [7:0] read_data_pipe;
    reg busy_pipe, arbitration_lost_pipe;

    assign sda = sda_drive_reg ? 1'b0 : 1'bz;
    assign scl = scl_drive_reg ? 1'b0 : 1'bz;
    wire sda_sensed = sda;

    assign read_data = read_data_reg;
    assign busy = busy_reg;
    assign arbitration_lost = arbitration_lost_reg;

    // Combinational logic produces next values into the *_pipe registers
    always @* begin
        // Default assignments
        arbitration_lost_pipe = arbitration_lost_reg;
        read_data_pipe = read_data_reg;
        busy_pipe = busy_reg;

        // Control logic before output registers (retimed)
        if (state_reg != 4'd0 && sda_drive_reg && !sda_sensed) begin
            arbitration_lost_pipe = 1'b1;
            // state_reg update remains in sequential always block to avoid race
        end

        // Other combinational logic for read_data_pipe, busy_pipe can be added here
        // For this example, we keep them unchanged
    end

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            arbitration_lost_reg <= 1'b0;
            read_data_reg <= 8'd0;
            busy_reg <= 1'b0;
            sda_drive_reg <= 1'b0;
            scl_drive_reg <= 1'b0;
            bit_pos_reg <= 4'd0;
            state_reg <= 4'd0;
            // Initialize pipe registers for reset consistency
            arbitration_lost_pipe <= 1'b0;
            read_data_pipe <= 8'd0;
            busy_pipe <= 1'b0;
        end else begin
            // Backward retiming: output registers are updated from pipe registers
            arbitration_lost_reg <= arbitration_lost_pipe;
            read_data_reg <= read_data_pipe;
            busy_reg <= busy_pipe;
            // State registers and drive logic update as needed
            if (state_reg != 4'd0 && sda_drive_reg && !sda_sensed) begin
                state_reg <= 4'd0;
            end
            // sda_drive_reg, scl_drive_reg, bit_pos_reg, and state_reg updates here as needed
        end
    end
endmodule