//SystemVerilog

// Top-level I2C master with timeout controller
module i2c_timeout_master(
    input        clk,
    input        rst_n,
    input  [6:0] slave_addr,
    input  [7:0] write_data,
    input        enable,
    output [7:0] read_data,
    output       busy,
    output       timeout_error,
    inout        scl,
    inout        sda
);
    // Internal signals
    wire        i2c_busy;
    wire [7:0]  i2c_read_data;
    wire        i2c_scl_out, i2c_sda_out, i2c_sda_oe;
    wire        timeout_err;
    wire        i2c_start;
    wire [3:0]  i2c_state;

    // Timeout controller signals
    wire [15:0] timeout_counter;
    wire        timeout_rst;

    // I2C operation is busy if I2C core is busy or timeout error
    assign busy = i2c_busy;
    assign read_data = i2c_read_data;
    assign timeout_error = timeout_err;

    // SCL/SDA buffer logic
    assign scl = i2c_scl_out ? 1'bz : 1'b0;
    assign sda = i2c_sda_oe ? 1'bz : i2c_sda_out;

    // I2C core submodule
    i2c_master_core u_i2c_core (
        .clk           (clk),
        .rst_n         (rst_n),
        .slave_addr    (slave_addr),
        .write_data    (write_data),
        .enable        (enable),
        .timeout_error (timeout_err),
        .read_data     (i2c_read_data),
        .busy          (i2c_busy),
        .state         (i2c_state),
        .scl_out       (i2c_scl_out),
        .sda_out       (i2c_sda_out),
        .sda_oe        (i2c_sda_oe)
    );

    // Timeout controller submodule
    i2c_timeout_ctrl u_timeout_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .enable         (enable),
        .state          (i2c_state),
        .timeout_error  (timeout_err),
        .timeout_counter(timeout_counter)
    );
endmodule

//-----------------------------------------------------------------------------
// I2C Master Core: Handles I2C protocol state machine and SCL/SDA drive logic
//-----------------------------------------------------------------------------
module i2c_master_core (
    input         clk,
    input         rst_n,
    input  [6:0]  slave_addr,
    input  [7:0]  write_data,
    input         enable,
    input         timeout_error,
    output reg [7:0] read_data,
    output reg    busy,
    output reg [3:0] state,
    output reg    scl_out,
    output reg    sda_out,
    output reg    sda_oe
);
    // State encoding
    localparam IDLE      = 4'd0;
    localparam START     = 4'd1;
    localparam ADDR      = 4'd2;
    localparam WRITE     = 4'd3;
    localparam READ      = 4'd4;
    localparam STOP      = 4'd5;
    localparam COMPLETE  = 4'd6;
    // ... (other states as needed)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            busy       <= 1'b0;
            read_data  <= 8'd0;
            scl_out    <= 1'b1;
            sda_out    <= 1'b1;
            sda_oe     <= 1'b1;
        end else begin
            if (timeout_error) begin
                // On timeout, reset state machine
                state      <= IDLE;
                busy       <= 1'b0;
                scl_out    <= 1'b1;
                sda_out    <= 1'b1;
                sda_oe     <= 1'b1;
            end else begin
                case (state)
                    IDLE: begin
                        busy      <= 1'b0;
                        scl_out   <= 1'b1;
                        sda_out   <= 1'b1;
                        sda_oe    <= 1'b1;
                        if (enable) begin
                            state <= START;
                            busy  <= 1'b1;
                        end
                    end
                    START: begin
                        // Generate START condition
                        scl_out <= 1'b1;
                        sda_out <= 1'b0;
                        sda_oe  <= 1'b0;
                        state   <= ADDR;
                    end
                    ADDR: begin
                        // Send address phase -- placeholder
                        // ... (actual address shifting logic)
                        state   <= WRITE;
                    end
                    WRITE: begin
                        // Write data phase -- placeholder
                        // ... (actual write shifting logic)
                        state   <= READ;
                    end
                    READ: begin
                        // Read data phase -- placeholder
                        // ... (actual read shifting logic)
                        read_data <= 8'hAA; // Dummy read value
                        state     <= STOP;
                    end
                    STOP: begin
                        // Generate STOP condition
                        scl_out <= 1'b1;
                        sda_out <= 1'b1;
                        sda_oe  <= 1'b1;
                        state   <= COMPLETE;
                    end
                    COMPLETE: begin
                        busy  <= 1'b0;
                        state <= IDLE;
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Timeout Controller: Monitors I2C state and triggers timeout error if needed
//-----------------------------------------------------------------------------
module i2c_timeout_ctrl(
    input         clk,
    input         rst_n,
    input         enable,
    input  [3:0]  state,
    output reg    timeout_error,
    output reg [15:0] timeout_counter
);
    localparam TIMEOUT = 16'd1000;

    wire [15:0] timeout_counter_next;
    wire        timeout_counter_carry;

    // 16-bit adder for timeout counter increment
    manchester_carry_chain_adder_16 u_timeout_counter_adder (
        .a   (timeout_counter),
        .b   (16'd1),
        .cin (1'b0),
        .sum (timeout_counter_next),
        .cout(timeout_counter_carry)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_counter <= 16'd0;
            timeout_error   <= 1'b0;
        end else if (state != 4'd0 && enable) begin
            timeout_counter <= timeout_counter_next;
            if (timeout_counter >= TIMEOUT) begin
                timeout_error   <= 1'b1;
            end
        end else begin
            timeout_counter <= 16'd0;
            timeout_error   <= 1'b0;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 16-bit Manchester Carry Chain Adder
//-----------------------------------------------------------------------------
module manchester_carry_chain_adder_16(
    input  [15:0] a,
    input  [15:0] b,
    input         cin,
    output [15:0] sum,
    output        cout
);
    wire [15:0] p; // propagate
    wire [15:0] g; // generate
    wire [16:0] c; // carry

    assign p = a ^ b;
    assign g = a & b;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : manchester_chain
            if (i == 0) begin
                assign c[1] = g[0] | (p[0] & c[0]);
            end else begin
                assign c[i+1] = g[i] | (p[i] & c[i]);
            end
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    assign cout = c[16];
endmodule