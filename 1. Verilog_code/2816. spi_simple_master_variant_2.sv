//SystemVerilog
module spi_simple_master(
    input  wire        clock,
    input  wire        reset,
    input  wire [7:0]  mosi_data,
    input  wire        start,
    output reg  [7:0]  miso_data,
    output reg         done,

    // SPI interface
    output reg         sck,
    output reg         mosi,
    input  wire        miso,
    output reg         ss
);

    // State Encoding (Gray code, 3 bits for 5 states)
    localparam [2:0] IDLE_G      = 3'b000;
    localparam [2:0] LOAD_G      = 3'b001;
    localparam [2:0] TRANSFER_G  = 3'b011;
    localparam [2:0] COMPLETE_G  = 3'b010;
    localparam [2:0] UNUSED_G    = 3'b110; // Placeholder for 5th state if needed

    reg [2:0]  current_state, next_state;

    // Pipeline registers for clear dataflow and timing
    reg [7:0]  mosi_data_stage;        // Stage 1: Latch input data
    reg [7:0]  shift_reg_stage;        // Stage 2: Shift register for SPI transfer
    reg [2:0]  bit_count_stage;        // Stage 2: Bit counter for SPI bits

    reg        sck_internal;           // Stage 2: Internal SCK
    reg        mosi_internal;          // Stage 2: Internal MOSI
    reg        ss_internal;            // Stage 2/3: Slave select

    // Pipeline register for SCK edge detection
    reg        sck_rise_edge;
    reg        sck_fall_edge;

    // Pipeline register for sampled MISO
    reg        miso_sampled;

    // Combinational logic for next state
    always @(*) begin : state_transition_logic
        case (current_state)
            IDLE_G: begin
                if (start)
                    next_state = LOAD_G;
                else
                    next_state = IDLE_G;
            end
            LOAD_G: begin
                next_state = TRANSFER_G;
            end
            TRANSFER_G: begin
                if ((bit_count_stage == 3'b000) && sck_rise_edge)
                    next_state = COMPLETE_G;
                else
                    next_state = TRANSFER_G;
            end
            COMPLETE_G: begin
                next_state = IDLE_G;
            end
            default: next_state = IDLE_G;
        endcase
    end

    // SCK generation and edge detection
    always @(posedge clock or posedge reset) begin : sck_pipeline
        if (reset) begin
            sck_internal    <= 1'b0;
            sck_rise_edge   <= 1'b0;
            sck_fall_edge   <= 1'b0;
        end else if (current_state == TRANSFER_G) begin
            sck_internal    <= ~sck_internal;
            sck_rise_edge   <= (~sck_internal) & 1'b1; // rising when toggled to 1
            sck_fall_edge   <= (sck_internal)  & 1'b1; // falling when toggled to 0
        end else begin
            sck_internal    <= 1'b0;
            sck_rise_edge   <= 1'b0;
            sck_fall_edge   <= 1'b0;
        end
    end

    // Pipeline: State and core dataflow
    always @(posedge clock or posedge reset) begin : datapath_pipeline
        if (reset) begin
            current_state      <= IDLE_G;
            mosi_data_stage    <= 8'h00;
            shift_reg_stage    <= 8'h00;
            bit_count_stage    <= 3'b000;
            mosi_internal      <= 1'b0;
            miso_sampled       <= 1'b0;
            ss_internal        <= 1'b1;
            miso_data          <= 8'h00;
            done               <= 1'b0;
        end else begin
            current_state <= next_state;

            case (current_state)
                IDLE_G: begin
                    mosi_internal   <= 1'b0;
                    done            <= 1'b0;
                    ss_internal     <= 1'b1;
                    if (start) begin
                        mosi_data_stage <= mosi_data;
                    end
                end
                LOAD_G: begin
                    shift_reg_stage <= mosi_data_stage;
                    bit_count_stage <= 3'b111;
                    ss_internal     <= 1'b0;
                    mosi_internal   <= mosi_data_stage[7];
                end
                TRANSFER_G: begin
                    ss_internal     <= 1'b0;
                    // On SCK falling edge, output MOSI
                    if (sck_fall_edge) begin
                        mosi_internal <= shift_reg_stage[7];
                    end
                    // On SCK rising edge, sample MISO and shift
                    if (sck_rise_edge) begin
                        shift_reg_stage <= {shift_reg_stage[6:0], miso};
                        if (bit_count_stage != 3'b000)
                            bit_count_stage <= bit_count_stage - 1'b1;
                    end
                end
                COMPLETE_G: begin
                    miso_data      <= shift_reg_stage;
                    done           <= 1'b1;
                    ss_internal    <= 1'b1;
                    mosi_internal  <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // Output assignments (registered for timing)
    always @(posedge clock or posedge reset) begin : output_registers
        if (reset) begin
            sck   <= 1'b0;
            mosi  <= 1'b0;
            ss    <= 1'b1;
        end else begin
            sck   <= sck_internal;
            mosi  <= mosi_internal;
            ss    <= ss_internal;
        end
    end

endmodule