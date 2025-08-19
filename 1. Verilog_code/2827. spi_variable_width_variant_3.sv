//SystemVerilog
module spi_variable_width(
    input              clk,
    input              rst_n,
    input      [4:0]   data_width, // 1-32 bits
    input      [31:0]  tx_data,
    input              start_tx,
    output reg [31:0]  rx_data,
    output reg         tx_done,
    output             sclk,
    output             cs_n,
    output             mosi,
    input              miso
);

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 1: Transaction Control and Initialization
    ////////////////////////////////////////////////////////////////////////////////
    reg        busy_flag_stage1;
    reg        tx_done_stage1;
    reg [4:0]  bit_counter_stage1;
    reg        start_tx_latched_stage1;
    reg [4:0]  data_width_latched_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_flag_stage1        <= 1'b0;
            tx_done_stage1          <= 1'b0;
            bit_counter_stage1      <= 5'd0;
            start_tx_latched_stage1 <= 1'b0;
            data_width_latched_stage1 <= 5'd0;
        end else begin
            start_tx_latched_stage1 <= start_tx;
            data_width_latched_stage1 <= data_width;
            if (start_tx && !busy_flag_stage1) begin
                busy_flag_stage1   <= 1'b1;
                tx_done_stage1     <= 1'b0;
                bit_counter_stage1 <= data_width;
            end else if (busy_flag_stage1 && (bit_counter_stage1 == 1)) begin
                busy_flag_stage1   <= 1'b0;
                tx_done_stage1     <= 1'b1;
            end else if (!busy_flag_stage1) begin
                tx_done_stage1     <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 2: SCLK Generation
    ////////////////////////////////////////////////////////////////////////////////
    reg        sclk_reg_stage2;
    reg        busy_flag_stage2;
    reg [4:0]  bit_counter_stage2;
    reg        tx_done_stage2;
    reg        start_tx_latched_stage2;
    reg [4:0]  data_width_latched_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_reg_stage2          <= 1'b0;
            busy_flag_stage2         <= 1'b0;
            bit_counter_stage2       <= 5'd0;
            tx_done_stage2           <= 1'b0;
            start_tx_latched_stage2  <= 1'b0;
            data_width_latched_stage2<= 5'd0;
        end else begin
            busy_flag_stage2         <= busy_flag_stage1;
            bit_counter_stage2       <= bit_counter_stage1;
            tx_done_stage2           <= tx_done_stage1;
            start_tx_latched_stage2  <= start_tx_latched_stage1;
            data_width_latched_stage2<= data_width_latched_stage1;
            if (busy_flag_stage1) begin
                sclk_reg_stage2 <= ~sclk_reg_stage2;
            end else begin
                sclk_reg_stage2 <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 3: Shift Register Operations
    ////////////////////////////////////////////////////////////////////////////////
    reg [31:0] tx_shift_reg_stage3;
    reg [31:0] rx_shift_reg_stage3;
    reg [4:0]  bit_counter_stage3;
    reg        sclk_reg_stage3;
    reg        busy_flag_stage3;
    reg        tx_done_stage3;
    reg        start_tx_latched_stage3;
    reg [4:0]  data_width_latched_stage3;
    reg [31:0] tx_data_latched_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg_stage3      <= 32'd0;
            rx_shift_reg_stage3      <= 32'd0;
            bit_counter_stage3       <= 5'd0;
            sclk_reg_stage3          <= 1'b0;
            busy_flag_stage3         <= 1'b0;
            tx_done_stage3           <= 1'b0;
            start_tx_latched_stage3  <= 1'b0;
            data_width_latched_stage3<= 5'd0;
            tx_data_latched_stage3   <= 32'd0;
        end else begin
            // Latch control and state signals from previous stage
            bit_counter_stage3       <= bit_counter_stage2;
            sclk_reg_stage3          <= sclk_reg_stage2;
            busy_flag_stage3         <= busy_flag_stage2;
            tx_done_stage3           <= tx_done_stage2;
            start_tx_latched_stage3  <= start_tx_latched_stage2;
            data_width_latched_stage3<= data_width_latched_stage2;
            tx_data_latched_stage3   <= tx_data;

            // TX Shift Register
            if (start_tx_latched_stage2 && !busy_flag_stage2) begin
                tx_shift_reg_stage3 <= tx_data << (32 - data_width_latched_stage2);
            end else if (busy_flag_stage2 && sclk_reg_stage2) begin // Falling edge
                tx_shift_reg_stage3 <= {tx_shift_reg_stage3[30:0], 1'b0};
            end

            // RX Shift Register
            if (start_tx_latched_stage2 && !busy_flag_stage2) begin
                rx_shift_reg_stage3 <= 32'd0;
            end else if (busy_flag_stage2 && !sclk_reg_stage2) begin // Rising edge
                rx_shift_reg_stage3 <= {rx_shift_reg_stage3[30:0], miso};
            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 4: Bit Counter Update
    ////////////////////////////////////////////////////////////////////////////////
    reg [4:0]  bit_counter_stage4;
    reg        busy_flag_stage4;
    reg        sclk_reg_stage4;
    reg        start_tx_latched_stage4;
    reg [4:0]  data_width_latched_stage4;
    reg        tx_done_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter_stage4       <= 5'd0;
            busy_flag_stage4         <= 1'b0;
            sclk_reg_stage4          <= 1'b0;
            start_tx_latched_stage4  <= 1'b0;
            data_width_latched_stage4<= 5'd0;
            tx_done_stage4           <= 1'b0;
        end else begin
            busy_flag_stage4         <= busy_flag_stage3;
            sclk_reg_stage4          <= sclk_reg_stage3;
            start_tx_latched_stage4  <= start_tx_latched_stage3;
            data_width_latched_stage4<= data_width_latched_stage3;
            tx_done_stage4           <= tx_done_stage3;

            if (start_tx_latched_stage3 && !busy_flag_stage3) begin
                bit_counter_stage4 <= data_width_latched_stage3;
            end else if (busy_flag_stage3 && sclk_reg_stage3) begin // Falling edge
                bit_counter_stage4 <= bit_counter_stage3 - 1'b1;
            end else begin
                bit_counter_stage4 <= bit_counter_stage3;
            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 5: Output Data Latch and Alignment
    ////////////////////////////////////////////////////////////////////////////////
    reg [31:0] rx_data_stage5;
    reg        tx_done_stage5;
    reg        busy_flag_stage5;
    reg [4:0]  bit_counter_stage5;
    reg        sclk_reg_stage5;
    reg [4:0]  data_width_latched_stage5;
    reg [31:0] rx_shift_reg_stage5;
    reg        miso_latched_stage5;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_stage5           <= 32'd0;
            tx_done_stage5           <= 1'b0;
            busy_flag_stage5         <= 1'b0;
            bit_counter_stage5       <= 5'd0;
            sclk_reg_stage5          <= 1'b0;
            data_width_latched_stage5<= 5'd0;
            rx_shift_reg_stage5      <= 32'd0;
            miso_latched_stage5      <= 1'b0;
        end else begin
            busy_flag_stage5         <= busy_flag_stage4;
            bit_counter_stage5       <= bit_counter_stage4;
            sclk_reg_stage5          <= sclk_reg_stage4;
            data_width_latched_stage5<= data_width_latched_stage4;
            tx_done_stage5           <= tx_done_stage4;
            rx_shift_reg_stage5      <= rx_shift_reg_stage3;
            miso_latched_stage5      <= miso;

            if (busy_flag_stage4 && (bit_counter_stage4 == 1) && sclk_reg_stage4) begin
                rx_data_stage5 <= (rx_shift_reg_stage3 << 1 | miso) >> (32 - data_width_latched_stage4);
            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Output Assignments
    ////////////////////////////////////////////////////////////////////////////////
    assign mosi = tx_shift_reg_stage3[31];
    assign sclk = busy_flag_stage2 ? sclk_reg_stage2 : 1'b0;
    assign cs_n = ~busy_flag_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 32'd0;
            tx_done <= 1'b0;
        end else begin
            rx_data <= rx_data_stage5;
            tx_done <= tx_done_stage5;
        end
    end

endmodule