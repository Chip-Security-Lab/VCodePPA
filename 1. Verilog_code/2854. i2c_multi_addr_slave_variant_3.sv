//SystemVerilog
module i2c_multi_addr_slave(
    input wire clk, rst,
    input wire [6:0] primary_addr, secondary_addr,
    output reg [7:0] rx_data,
    output reg rx_valid,
    inout wire sda, scl
);
    reg sda_dir, sda_out;
    reg [2:0] state;
    reg [7:0] shift_reg_d, shift_reg_q;
    reg [3:0] bit_idx_d, bit_idx_q;
    reg addr_match_d, addr_match_q;
    reg start_det_d, start_det_q;
    reg scl_prev_d, scl_prev_q;
    reg sda_prev_d, sda_prev_q;

    wire scl_sync, sda_sync;

    assign sda = sda_dir ? sda_out : 1'bz;

    // Synchronize scl and sda to clk domain
    reg scl_meta, scl_sync_r;
    reg sda_meta, sda_sync_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_meta    <= 1'b0;
            scl_sync_r  <= 1'b0;
            sda_meta    <= 1'b0;
            sda_sync_r  <= 1'b0;
        end else begin
            scl_meta    <= scl;
            scl_sync_r  <= scl_meta;
            sda_meta    <= sda;
            sda_sync_r  <= sda_meta;
        end
    end

    assign scl_sync = scl_sync_r;
    assign sda_sync = sda_sync_r;

    // Combinational logic for start detection
    always @* begin
        scl_prev_d   = scl_sync;
        sda_prev_d   = sda_sync;
        start_det_d  = scl_sync & scl_prev_q & ~sda_sync & sda_prev_q;
    end

    // Optimized address comparison logic
    function addr_match_fn;
        input [7:1] addr_bits;
        input [6:0] pri_addr;
        input [6:0] sec_addr;
        begin
            // If primary and secondary are equal, only one comparison needed
            if (pri_addr == sec_addr)
                addr_match_fn = (addr_bits == pri_addr);
            else begin
                // Hardware efficient: check if within [min,max] then do equality
                if ((addr_bits >= ((pri_addr < sec_addr) ? pri_addr : sec_addr)) &&
                    (addr_bits <= ((pri_addr > sec_addr) ? pri_addr : sec_addr))) begin
                    addr_match_fn = (addr_bits == pri_addr) | (addr_bits == sec_addr);
                end else begin
                    addr_match_fn = 1'b0;
                end
            end
        end
    endfunction

    // Main state machine combinational logic
    reg [2:0] state_d;
    reg sda_dir_d, sda_out_d;
    reg rx_valid_d;
    reg [7:0] rx_data_d;

    always @* begin
        // Default assignments
        state_d       = state;
        sda_dir_d     = sda_dir;
        sda_out_d     = sda_out;
        bit_idx_d     = bit_idx_q;
        shift_reg_d   = shift_reg_q;
        addr_match_d  = addr_match_q;
        rx_data_d     = rx_data;
        rx_valid_d    = 1'b0;

        case (state)
            3'b000: begin
                if (start_det_q) begin
                    state_d      = 3'b001;
                    bit_idx_d    = 4'b0000;
                    shift_reg_d  = 8'h00;
                end
            end
            3'b001: begin
                if (bit_idx_q == 4'd7) begin
                    // Optimized address comparison
                    addr_match_d = addr_match_fn(shift_reg_q[7:1], primary_addr, secondary_addr);
                    state_d      = addr_match_d ? 3'b010 : 3'b000;
                    sda_dir_d    = addr_match_d;
                    sda_out_d    = 1'b0;
                end else if (scl_sync) begin
                    shift_reg_d = {shift_reg_q[6:0], sda_sync};
                    bit_idx_d   = bit_idx_q + 1'b1;
                end
            end
            3'b010: begin
                state_d    = 3'b011;
                bit_idx_d  = 4'b0000;
                sda_dir_d  = 1'b0;
            end
            3'b011: begin
                if (bit_idx_q == 4'd7) begin
                    rx_data_d  = shift_reg_q;
                    rx_valid_d = 1'b1;
                    state_d    = 3'b000;
                end else if (scl_sync) begin
                    shift_reg_d = {shift_reg_q[6:0], sda_sync};
                    bit_idx_d   = bit_idx_q + 1'b1;
                end
            end
            default: state_d = 3'b000;
        endcase
    end

    // Registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= 3'b000;
            rx_valid      <= 1'b0;
            sda_dir       <= 1'b0;
            sda_out       <= 1'b0;
            bit_idx_q     <= 4'b0000;
            shift_reg_q   <= 8'h00;
            addr_match_q  <= 1'b0;
            scl_prev_q    <= 1'b0;
            sda_prev_q    <= 1'b0;
            start_det_q   <= 1'b0;
            rx_data       <= 8'h00;
        end else begin
            state         <= state_d;
            sda_dir       <= sda_dir_d;
            sda_out       <= sda_out_d;
            bit_idx_q     <= bit_idx_d;
            shift_reg_q   <= shift_reg_d;
            addr_match_q  <= addr_match_d;
            scl_prev_q    <= scl_prev_d;
            sda_prev_q    <= sda_prev_d;
            start_det_q   <= start_det_d;
            rx_data       <= rx_data_d;
            rx_valid      <= rx_valid_d;
        end
    end

endmodule