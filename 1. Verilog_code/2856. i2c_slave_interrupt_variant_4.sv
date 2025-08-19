//SystemVerilog
module i2c_slave_interrupt_axi_stream #(
    parameter DATA_WIDTH = 8
)(
    input wire                  clk,
    input wire                  reset,
    input wire [6:0]            device_addr,
    // AXI-Stream Master Output Interface
    output reg [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                  m_axis_tvalid,
    input  wire                 m_axis_tready,
    output reg                  m_axis_tlast,
    // Interrupt Outputs
    output reg                  addr_match_int,
    output reg                  data_int,
    output reg                  error_int,
    // I2C Interface
    inout wire                  sda,
    inout wire                  scl
);

    // Internal registers
    reg [3:0]           bit_count;
    reg [2:0]           state;
    reg [DATA_WIDTH-1:0] rx_shift_reg;
    reg                 sda_in_r, scl_in_r, sda_out;
    reg                 sda_oe;
    wire                sda_in, scl_in;

    // I2C Input buffers
    assign sda_in = sda;
    assign scl_in = scl;

    // Bidirectional SDA line
    assign sda = (sda_oe == 1'b1) ? sda_out : 1'bz;

    // Start/Stop Condition Detection
    wire start_condition;
    wire stop_condition;
    assign start_condition = (scl_in_r == 1'b1) && (sda_in_r == 1'b1) && (sda_in == 1'b0);
    assign stop_condition  = (scl_in_r == 1'b1) && (sda_in_r == 1'b0) && (sda_in == 1'b1);

    // Synchronize SDA and SCL
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_in_r <= 1'b1;
            scl_in_r <= 1'b1;
        end else begin
            sda_in_r <= sda_in;
            scl_in_r <= scl_in;
        end
    end

    // State Machine
    localparam IDLE       = 3'b000;
    localparam ADDR_MATCH = 3'b001;
    localparam RX_DATA    = 3'b010;
    localparam DATA_DONE  = 3'b011;
    localparam ERROR      = 3'b100;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            addr_match_int  <= 1'b0;
            data_int        <= 1'b0;
            error_int       <= 1'b0;
            m_axis_tdata    <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid   <= 1'b0;
            m_axis_tlast    <= 1'b0;
            rx_shift_reg    <= {DATA_WIDTH{1'b0}};
            bit_count       <= 4'd0;
            sda_out         <= 1'b1;
            sda_oe          <= 1'b0;
        end else begin
            // Default signal assignments
            addr_match_int  <= 1'b0;
            error_int       <= 1'b0;

            case (state)
                IDLE: begin
                    data_int      <= 1'b0;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast  <= 1'b0;
                    bit_count     <= 4'd0;
                    if (start_condition) begin
                        state <= ADDR_MATCH;
                    end
                end

                ADDR_MATCH: begin
                    // Simulate address reception; in a real I2C slave, shift in bits here
                    // For demonstration, assume address is matched after 8 bits
                    if (bit_count < 4'd7) begin
                        bit_count <= bit_count + 1;
                        rx_shift_reg[6:0] <= (rx_shift_reg[6:0] << 1) | sda_in;
                    end else begin
                        if (rx_shift_reg[6:0] == device_addr) begin
                            addr_match_int <= 1'b1;
                            state <= RX_DATA;
                            bit_count <= 4'd0;
                        end else begin
                            error_int <= 1'b1;
                            state <= ERROR;
                        end
                    end
                end

                RX_DATA: begin
                    // Simulate data reception; shift in data bits
                    if (bit_count < 4'd7) begin
                        bit_count <= bit_count + 1;
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_in};
                    end else begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_in};
                        state <= DATA_DONE;
                    end
                end

                DATA_DONE: begin
                    // Output data via AXI-Stream when tready is high
                    if ((m_axis_tvalid == 1'b0) && (data_int == 1'b0)) begin
                        m_axis_tdata  <= rx_shift_reg;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast  <= 1'b1;
                        data_int      <= 1'b1;
                    end
                    if ((m_axis_tvalid == 1'b1) && (m_axis_tready == 1'b1)) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast  <= 1'b0;
                        state         <= IDLE;
                        data_int      <= 1'b0;
                    end
                end

                ERROR: begin
                    // Remain in error state until stop condition
                    if (stop_condition) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule