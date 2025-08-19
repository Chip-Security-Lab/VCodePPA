//SystemVerilog
module dual_mode_spi(
    input            clk,
    input            rst_n,
    input            mode,         // 0: Standard, 1: Dual IO
    input  [7:0]     tx_data,
    input            start,
    output reg [7:0] rx_data,
    output reg       done,
    output reg       sck,
    output reg       cs_n,
    inout            io0,          // MOSI in standard mode
    inout            io1           // MISO in standard mode
);

    // Pipeline registers for data/control path
    reg  [7:0] tx_shift_stage1, tx_shift_stage2;
    reg  [7:0] rx_shift_stage1, rx_shift_stage2;
    reg  [2:0] bit_count_stage1, bit_count_stage2;
    reg        io0_out_stage1, io0_out_stage2;
    reg        io1_out_stage1, io1_out_stage2;
    reg        io0_oe_stage1, io0_oe_stage2;
    reg        io1_oe_stage1, io1_oe_stage2;
    reg        sck_stage1, sck_stage2;
    reg        cs_n_stage1, cs_n_stage2;
    reg        done_stage1, done_stage2;
    reg  [7:0] rx_data_stage1, rx_data_stage2;

    // Tri-state buffer control
    assign io0 = io0_oe_stage2 ? io0_out_stage2 : 1'bz;
    assign io1 = io1_oe_stage2 ? io1_out_stage2 : 1'bz;

    // Pipeline Stage 1: Control & Data Path Calculation
    reg  [7:0] tx_shift_ctrl;
    reg  [7:0] rx_shift_ctrl;
    reg  [2:0] bit_count_ctrl;
    reg        io0_out_ctrl;
    reg        io1_out_ctrl;
    reg        io0_oe_ctrl;
    reg        io1_oe_ctrl;
    reg        sck_ctrl;
    reg        cs_n_ctrl;
    reg        done_ctrl;
    reg  [7:0] rx_data_ctrl;

    always @* begin : main_control_stage1
        // Default assignments from previous stage2 (pipeline register)
        tx_shift_ctrl   = tx_shift_stage2;
        rx_shift_ctrl   = rx_shift_stage2;
        bit_count_ctrl  = bit_count_stage2;
        io0_out_ctrl    = io0_out_stage2;
        io1_out_ctrl    = io1_out_stage2;
        io0_oe_ctrl     = io0_oe_stage2;
        io1_oe_ctrl     = io1_oe_stage2;
        sck_ctrl        = sck_stage2;
        cs_n_ctrl       = cs_n_stage2;
        done_ctrl       = done_stage2;
        rx_data_ctrl    = rx_data_stage2;

        if (!rst_n) begin
            tx_shift_ctrl   = 8'h00;
            rx_shift_ctrl   = 8'h00;
            bit_count_ctrl  = 3'h0;
            sck_ctrl        = 1'b0;
            cs_n_ctrl       = 1'b1;
            done_ctrl       = 1'b0;
            io0_oe_ctrl     = 1'b0;
            io1_oe_ctrl     = 1'b0;
            io0_out_ctrl    = 1'b0;
            io1_out_ctrl    = 1'b0;
            rx_data_ctrl    = 8'h00;
        end else if (start && cs_n_stage2) begin
            tx_shift_ctrl   = tx_data;
            bit_count_ctrl  = mode ? 3'h3 : 3'h7; // 4 or 8 bits
            cs_n_ctrl       = 1'b0;
            io0_oe_ctrl     = 1'b1;
            io1_oe_ctrl     = mode ? 1'b1 : 1'b0;
            sck_ctrl        = 1'b0;
            done_ctrl       = 1'b0;
            rx_shift_ctrl   = 8'h00;
            io0_out_ctrl    = 1'b0;
            io1_out_ctrl    = 1'b0;
            rx_data_ctrl    = rx_data_stage2;
        end else if (!cs_n_stage2) begin
            sck_ctrl = ~sck_stage2;
            // SCK Rising Edge: Sample Inputs
            if (sck_stage2) begin
                if (mode) begin
                    rx_shift_ctrl = {rx_shift_stage2[5:0], io1, io0};
                    bit_count_ctrl = (bit_count_stage2 == 0) ? 0 : bit_count_stage2 - 1;
                end else begin
                    rx_shift_ctrl = {rx_shift_stage2[6:0], io1};
                    bit_count_ctrl = (bit_count_stage2 == 0) ? 0 : bit_count_stage2 - 1;
                end
                io0_out_ctrl = io0_out_stage2;
                io1_out_ctrl = io1_out_stage2;
            end else begin
                // SCK Falling Edge: Shift Out
                if (mode) begin
                    io0_out_ctrl = tx_shift_stage2[1];
                    io1_out_ctrl = tx_shift_stage2[0];
                    tx_shift_ctrl = {tx_shift_stage2[5:0], 2'b00};
                end else begin
                    io0_out_ctrl = tx_shift_stage2[7];
                    tx_shift_ctrl = {tx_shift_stage2[6:0], 1'b0};
                end
                if (bit_count_stage2 == 0) begin
                    cs_n_ctrl = 1'b1;
                    done_ctrl = 1'b1;
                    rx_data_ctrl = rx_shift_stage2;
                    io0_oe_ctrl = 1'b0;
                    io1_oe_ctrl = 1'b0;
                end else begin
                    done_ctrl = 1'b0;
                    rx_data_ctrl = rx_data_stage2;
                end
            end
        end else begin
            done_ctrl = 1'b0;
            rx_data_ctrl = rx_data_stage2;
        end
    end

    // Pipeline Stage 1 Registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_stage1  <= 8'h00;
            rx_shift_stage1  <= 8'h00;
            bit_count_stage1 <= 3'h0;
            io0_out_stage1   <= 1'b0;
            io1_out_stage1   <= 1'b0;
            io0_oe_stage1    <= 1'b0;
            io1_oe_stage1    <= 1'b0;
            sck_stage1       <= 1'b0;
            cs_n_stage1      <= 1'b1;
            done_stage1      <= 1'b0;
            rx_data_stage1   <= 8'h00;
        end else begin
            tx_shift_stage1  <= tx_shift_ctrl;
            rx_shift_stage1  <= rx_shift_ctrl;
            bit_count_stage1 <= bit_count_ctrl;
            io0_out_stage1   <= io0_out_ctrl;
            io1_out_stage1   <= io1_out_ctrl;
            io0_oe_stage1    <= io0_oe_ctrl;
            io1_oe_stage1    <= io1_oe_ctrl;
            sck_stage1       <= sck_ctrl;
            cs_n_stage1      <= cs_n_ctrl;
            done_stage1      <= done_ctrl;
            rx_data_stage1   <= rx_data_ctrl;
        end
    end

    // Pipeline Stage 2: Output Registering (retiming for clear dataflow)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_stage2  <= 8'h00;
            rx_shift_stage2  <= 8'h00;
            bit_count_stage2 <= 3'h0;
            io0_out_stage2   <= 1'b0;
            io1_out_stage2   <= 1'b0;
            io0_oe_stage2    <= 1'b0;
            io1_oe_stage2    <= 1'b0;
            sck_stage2       <= 1'b0;
            cs_n_stage2      <= 1'b1;
            done_stage2      <= 1'b0;
            rx_data_stage2   <= 8'h00;
        end else begin
            tx_shift_stage2  <= tx_shift_stage1;
            rx_shift_stage2  <= rx_shift_stage1;
            bit_count_stage2 <= bit_count_stage1;
            io0_out_stage2   <= io0_out_stage1;
            io1_out_stage2   <= io1_out_stage1;
            io0_oe_stage2    <= io0_oe_stage1;
            io1_oe_stage2    <= io1_oe_stage1;
            sck_stage2       <= sck_stage1;
            cs_n_stage2      <= cs_n_stage1;
            done_stage2      <= done_stage1;
            rx_data_stage2   <= rx_data_stage1;
        end
    end

    // Output assignments from final pipeline stage
    always @(*) begin
        sck    = sck_stage2;
        cs_n   = cs_n_stage2;
        done   = done_stage2;
        rx_data= rx_data_stage2;
    end

endmodule