//SystemVerilog
module i2c_slave_interrupt_valid_ready (
    input  wire        clk,
    input  wire        reset,
    input  wire [6:0]  device_addr,
    output wire [7:0]  data_out,
    output wire        addr_match_int,
    output wire        error_int,
    input  wire        data_out_ready,
    output wire        data_out_valid,
    inout  wire        sda,
    inout  wire        scl
);

    // Internal wires for combinational and registered signals
    wire [3:0]  bit_count_next;
    wire [2:0]  state_next;
    wire [7:0]  rx_shift_reg_next;
    wire        sda_in_next, scl_in_next, sda_out_next;
    wire        data_int_next;
    wire        data_out_valid_next;
    wire [7:0]  data_out_next;
    wire        addr_match_int_next;
    wire        error_int_next;

    // Registered signals
    reg  [3:0]  bit_count_reg;
    reg  [2:0]  state_reg;
    reg  [7:0]  rx_shift_reg_reg;
    reg         sda_in_reg, scl_in_reg, sda_out_reg;
    reg         data_int_reg;
    reg         data_out_valid_reg;
    reg  [7:0]  data_out_reg;
    reg         addr_match_int_reg;
    reg         error_int_reg;

    // Synchronize SDA and SCL inputs (separated sequential logic)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_in_reg <= 1'b1;
            scl_in_reg <= 1'b1;
        end else begin
            sda_in_reg <= sda;
            scl_in_reg <= scl;
        end
    end

    // Combinational logic for start/stop condition
    wire start_condition = scl_in_reg && sda_in_reg && !sda;
    wire stop_condition  = scl_in_reg && !sda_in_reg && sda;

    // Combinational logic for next state and outputs
    i2c_slave_irq_comb u_comb (
        .clk(clk),
        .reset(reset),
        .state_cur(state_reg),
        .bit_count_cur(bit_count_reg),
        .rx_shift_reg_cur(rx_shift_reg_reg),
        .data_out_reg_cur(data_out_reg),
        .addr_match_int_reg_cur(addr_match_int_reg),
        .data_int_reg_cur(data_int_reg),
        .data_out_valid_reg_cur(data_out_valid_reg),
        .error_int_reg_cur(error_int_reg),
        .start_condition(start_condition),
        .stop_condition(stop_condition),
        .data_out_ready(data_out_ready),

        .bit_count_next(bit_count_next),
        .state_next(state_next),
        .rx_shift_reg_next(rx_shift_reg_next),
        .data_out_next(data_out_next),
        .addr_match_int_next(addr_match_int_next),
        .data_int_next(data_int_next),
        .data_out_valid_next(data_out_valid_next),
        .error_int_next(error_int_next)
    );

    // Sequential logic for state and outputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg          <= 3'b000;
            bit_count_reg      <= 4'd0;
            rx_shift_reg_reg   <= 8'd0;
            data_out_reg       <= 8'd0;
            addr_match_int_reg <= 1'b0;
            data_int_reg       <= 1'b0;
            data_out_valid_reg <= 1'b0;
            error_int_reg      <= 1'b0;
        end else begin
            state_reg          <= state_next;
            bit_count_reg      <= bit_count_next;
            rx_shift_reg_reg   <= rx_shift_reg_next;
            data_out_reg       <= data_out_next;
            addr_match_int_reg <= addr_match_int_next;
            data_int_reg       <= data_int_next;
            data_out_valid_reg <= data_out_valid_next;
            error_int_reg      <= error_int_next;
        end
    end

    // Output assignments
    assign data_out       = data_out_reg;
    assign addr_match_int = addr_match_int_reg;
    assign error_int      = error_int_reg;
    assign data_out_valid = data_out_valid_reg;

    // Tie unused signals to default values
    assign sda = 1'bz;
    assign scl = 1'bz;

endmodule

// Combinational logic module
module i2c_slave_irq_comb (
    input  wire        clk,
    input  wire        reset,
    input  wire [2:0]  state_cur,
    input  wire [3:0]  bit_count_cur,
    input  wire [7:0]  rx_shift_reg_cur,
    input  wire [7:0]  data_out_reg_cur,
    input  wire        addr_match_int_reg_cur,
    input  wire        data_int_reg_cur,
    input  wire        data_out_valid_reg_cur,
    input  wire        error_int_reg_cur,
    input  wire        start_condition,
    input  wire        stop_condition,
    input  wire        data_out_ready,

    output reg  [3:0]  bit_count_next,
    output reg  [2:0]  state_next,
    output reg  [7:0]  rx_shift_reg_next,
    output reg  [7:0]  data_out_next,
    output reg         addr_match_int_next,
    output reg         data_int_next,
    output reg         data_out_valid_next,
    output reg         error_int_next
);

    always @(*) begin
        // Default assignments: hold values
        bit_count_next        = bit_count_cur;
        state_next            = state_cur;
        rx_shift_reg_next     = rx_shift_reg_cur;
        data_out_next         = data_out_reg_cur;
        addr_match_int_next   = addr_match_int_reg_cur;
        data_int_next         = data_int_reg_cur;
        data_out_valid_next   = data_out_valid_reg_cur;
        error_int_next        = error_int_reg_cur;

        // By default, deassert valid if handshake
        if (data_out_valid_reg_cur && data_out_ready) begin
            data_out_valid_next = 1'b0;
        end

        case (state_cur)
            3'b000: begin // Idle, wait for start condition
                addr_match_int_next = 1'b0;
                data_int_next       = 1'b0;
                if (start_condition) begin
                    state_next = 3'b001;
                end
            end
            3'b001: begin // Receive address, simplified for example
                // ... address reception logic here ...
                // For demonstration, assume address is received and matches
                addr_match_int_next = 1'b1;
                state_next = 3'b010;
            end
            3'b010: begin // Receive data
                // ... data reception logic here ...
                // For demonstration, assume data is received
                rx_shift_reg_next = 8'hAA; // Example data
                state_next = 3'b011;
            end
            3'b011: begin // Data ready to output
                if (!data_out_valid_reg_cur) begin
                    data_out_next       = rx_shift_reg_cur;
                    data_out_valid_next = 1'b1;
                    data_int_next       = 1'b1;
                end
                if (data_out_valid_reg_cur && data_out_ready) begin
                    data_int_next   = 1'b0;
                    state_next      = 3'b000;
                end
            end
            default: state_next = 3'b000;
        endcase
    end

endmodule