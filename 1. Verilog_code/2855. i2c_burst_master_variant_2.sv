//SystemVerilog
module i2c_burst_master_axi_stream (
    input              clk,
    input              rstn,
    // AXI-Stream slave interface for input burst write data
    input              s_axis_tvalid,
    output             s_axis_tready,
    input      [7:0]   s_axis_tdata,
    input              s_axis_tlast,
    // AXI-Stream master interface for output burst read data
    output reg         m_axis_tvalid,
    input              m_axis_tready,
    output reg [7:0]   m_axis_tdata,
    output reg         m_axis_tlast,
    // Control interface
    input              ctrl_start,
    input      [6:0]   ctrl_dev_addr,
    input      [7:0]   ctrl_mem_addr,
    input      [1:0]   ctrl_byte_count,
    output reg         ctrl_busy,
    output reg         ctrl_done,
    // I2C interface
    inout              scl,
    inout              sda
);

    // I2C line control
    reg scl_drive_low, sda_drive_low;
    reg [7:0] tx_shift_reg;
    reg [3:0] fsm_state, fsm_next_state;
    reg [1:0] byte_ptr;
    reg [7:0] write_buffer [0:3];
    reg [7:0] read_buffer [0:3];
    reg [1:0] write_cnt;
    reg       write_phase_active;
    reg       read_phase_active;
    reg       axis_tready_int;
    reg [1:0] read_cnt;
    reg       axis_stream_active;

    assign scl = scl_drive_low ? 1'b0 : 1'bz;
    assign sda = sda_drive_low ? tx_shift_reg[7] : 1'bz;

    assign s_axis_tready = axis_tready_int;

    // FSM state encoding
    localparam IDLE_STATE            = 4'h0;
    localparam LOAD_WRITE_STATE      = 4'h1;
    localparam WRITE_I2C_START_STATE = 4'h2;
    localparam WRITE_I2C_STATE       = 4'h3;
    localparam WRITE_I2C_WAIT_STATE  = 4'h4;
    localparam READ_I2C_START_STATE  = 4'h5;
    localparam READ_I2C_STATE        = 4'h6;
    localparam READ_I2C_WAIT_STATE   = 4'h7;
    localparam OUTPUT_STREAM_STATE   = 4'h8;
    localparam DONE_STATE            = 4'h9;

    // Input AXI-Stream data loading
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            write_cnt      <= 2'b00;
            axis_stream_active    <= 1'b0;
        end else begin
            if (fsm_state == IDLE_STATE) begin
                write_cnt   <= 2'b00;
                axis_stream_active <= 1'b0;
            end else if (fsm_state == LOAD_WRITE_STATE && s_axis_tvalid && axis_tready_int) begin
                write_buffer[write_cnt] <= s_axis_tdata;
                write_cnt   <= write_cnt + 1'b1;
                axis_stream_active <= 1'b1;
            end
        end
    end

    // AXI-Stream tready generation for slave interface (optimized)
    always @(*) begin
        axis_tready_int = (fsm_state == LOAD_WRITE_STATE) && (write_cnt < ctrl_byte_count);
    end

    // AXI-Stream output logic for master interface (optimized comparison)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 8'b0;
            m_axis_tlast  <= 1'b0;
            read_cnt    <= 2'b00;
        end else begin
            if ((fsm_state == OUTPUT_STREAM_STATE) && ~m_axis_tvalid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= read_buffer[read_cnt];
                m_axis_tlast  <= (read_cnt + 1'b1 == ctrl_byte_count);
            end else if (m_axis_tvalid && m_axis_tready) begin
                if ((read_cnt + 1'b1) == ctrl_byte_count) begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast  <= 1'b0;
                    read_cnt    <= 2'b00;
                end else begin
                    read_cnt    <= read_cnt + 1'b1;
                    m_axis_tdata  <= read_buffer[read_cnt + 1'b1];
                    m_axis_tlast  <= (read_cnt + 2'b10 == ctrl_byte_count);
                end
            end else if (fsm_state != OUTPUT_STREAM_STATE) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
                read_cnt    <= 2'b00;
            end
        end
    end

    // State transition logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            fsm_state <= IDLE_STATE;
        else
            fsm_state <= fsm_next_state;
    end

    // FSM next state logic (optimized comparison chains)
    always @(*) begin
        fsm_next_state = fsm_state;
        case (fsm_state)
            IDLE_STATE: begin
                if (ctrl_start)
                    fsm_next_state = LOAD_WRITE_STATE;
            end
            LOAD_WRITE_STATE: begin
                if ((write_cnt == ctrl_byte_count) && axis_stream_active)
                    fsm_next_state = WRITE_I2C_START_STATE;
            end
            WRITE_I2C_START_STATE: begin
                fsm_next_state = WRITE_I2C_STATE;
            end
            WRITE_I2C_STATE: begin
                if (byte_ptr + 1'b1 == ctrl_byte_count)
                    fsm_next_state = READ_I2C_START_STATE;
                else
                    fsm_next_state = WRITE_I2C_WAIT_STATE;
            end
            WRITE_I2C_WAIT_STATE: begin
                fsm_next_state = WRITE_I2C_STATE;
            end
            READ_I2C_START_STATE: begin
                fsm_next_state = READ_I2C_STATE;
            end
            READ_I2C_STATE: begin
                if (byte_ptr + 1'b1 == ctrl_byte_count)
                    fsm_next_state = OUTPUT_STREAM_STATE;
                else
                    fsm_next_state = READ_I2C_WAIT_STATE;
            end
            READ_I2C_WAIT_STATE: begin
                fsm_next_state = READ_I2C_STATE;
            end
            OUTPUT_STREAM_STATE: begin
                if (m_axis_tvalid && m_axis_tready && m_axis_tlast)
                    fsm_next_state = DONE_STATE;
            end
            DONE_STATE: begin
                fsm_next_state = IDLE_STATE;
            end
            default: fsm_next_state = IDLE_STATE;
        endcase
    end

    // Main data path and control logic (optimized comparison and structure)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ctrl_busy       <= 1'b0;
            ctrl_done       <= 1'b0;
            byte_ptr        <= 2'b00;
            tx_shift_reg    <= 8'b0;
            scl_drive_low   <= 1'b0;
            sda_drive_low   <= 1'b0;
            read_phase_active      <= 1'b0;
            write_phase_active     <= 1'b0;
            read_buffer[0] <= 8'b0;
            read_buffer[1] <= 8'b0;
            read_buffer[2] <= 8'b0;
            read_buffer[3] <= 8'b0;
        end else begin
            case (fsm_state)
                IDLE_STATE: begin
                    ctrl_busy    <= 1'b0;
                    ctrl_done    <= 1'b0;
                    byte_ptr   <= 2'b00;
                    scl_drive_low<= 1'b0;
                    sda_drive_low<= 1'b0;
                    write_phase_active  <= 1'b0;
                    read_phase_active   <= 1'b0;
                end
                LOAD_WRITE_STATE: begin
                    ctrl_busy    <= 1'b1;
                    ctrl_done    <= 1'b0;
                end
                WRITE_I2C_START_STATE: begin
                    write_phase_active  <= 1'b1;
                    byte_ptr   <= 2'b00;
                end
                WRITE_I2C_STATE: begin
                    tx_shift_reg <= write_buffer[byte_ptr];
                    scl_drive_low<= 1'b1;
                    sda_drive_low<= 1'b1;
                    if (byte_ptr + 1'b1 < ctrl_byte_count)
                        byte_ptr <= byte_ptr + 1'b1;
                end
                WRITE_I2C_WAIT_STATE: begin
                    scl_drive_low<= 1'b0;
                    sda_drive_low<= 1'b0;
                end
                READ_I2C_START_STATE: begin
                    read_phase_active   <= 1'b1;
                    byte_ptr   <= 2'b00;
                end
                READ_I2C_STATE: begin
                    scl_drive_low<= 1'b1;
                    sda_drive_low<= 1'b0;
                    read_buffer[byte_ptr] <= {6'b0, ctrl_dev_addr[1:0]};
                    if (byte_ptr + 1'b1 < ctrl_byte_count)
                        byte_ptr <= byte_ptr + 1'b1;
                end
                READ_I2C_WAIT_STATE: begin
                    scl_drive_low<= 1'b0;
                end
                OUTPUT_STREAM_STATE: begin
                    ctrl_busy    <= 1'b1;
                end
                DONE_STATE: begin
                    ctrl_busy    <= 1'b0;
                    ctrl_done    <= 1'b1;
                    write_phase_active  <= 1'b0;
                    read_phase_active   <= 1'b0;
                end
                default: ;
            endcase
        end
    end

endmodule