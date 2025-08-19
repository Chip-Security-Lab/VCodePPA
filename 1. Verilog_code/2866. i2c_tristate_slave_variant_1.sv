//SystemVerilog
module i2c_tristate_slave(
    input clk_i, rst_i,
    input [6:0] addr_i,
    output reg [7:0] data_o,
    output reg valid_o,
    inout sda_io, scl_io
);
    // Tristate control signals
    reg sda_oe, sda_o, scl_oe, scl_o;
    
    // State and data registers
    reg [2:0] state_r, state_next;
    reg [7:0] shift_r;
    reg [2:0] bit_cnt, bit_cnt_next;
    
    // Pipeline registers for critical path cutting
    reg start_detected, start_detected_pipe;
    reg sda_i_reg, scl_i_reg;
    reg addr_match_reg;
    reg [7:0] shift_next;
    reg sda_oe_next, valid_o_next;
    
    // Tristate control
    assign sda_io = sda_oe ? 1'bz : sda_o;
    assign scl_io = scl_oe ? 1'bz : scl_o;
    
    // Input sampling with registered inputs to cut input path
    wire sda_i = sda_io;
    wire scl_i = scl_io;
    
    // Input registration stage
    always @(posedge clk_i) begin
        sda_i_reg <= sda_i;
        scl_i_reg <= scl_i;
    end
    
    // Start condition detection with pipelining
    always @(posedge clk_i) begin
        if (scl_i_reg && sda_i_reg && !sda_o)
            start_detected <= 1'b1;
        else
            start_detected <= 1'b0;
            
        // Pipeline the start detection signal
        start_detected_pipe <= start_detected;
    end
    
    // Address comparison pipeline stage
    always @(posedge clk_i) begin
        addr_match_reg <= (shift_r[7:1] == addr_i);
    end
    
    // Han-Carlson adder signals
    wire [7:0] hc_sum;
    wire hc_cout;
    
    // Next state and output logic (split combinational logic)
    always @(*) begin
        // Default assignments to prevent latches
        state_next = state_r;
        bit_cnt_next = bit_cnt;
        shift_next = shift_r;
        sda_oe_next = sda_oe;
        valid_o_next = 1'b0;
        
        case(state_r)
            3'b000: if (start_detected_pipe) begin
                state_next = 3'b001;
                bit_cnt_next = 3'b000;
            end
            
            3'b001: if (bit_cnt == 3'b111) begin
                state_next = 3'b010;
                if (addr_match_reg)
                    sda_oe_next = 1'b0; // ACK
            end else if (scl_i_reg) begin
                shift_next = {shift_r[6:0], sda_i_reg};
                bit_cnt_next = hc_add_3bit(bit_cnt, 3'b001);  // Use Han-Carlson adder
            end
            
            3'b010: begin
                state_next = 3'b011;
                sda_oe_next = 1'b1;
            end
            
            3'b011: if (bit_cnt == 3'b111) begin
                state_next = 3'b100;
                valid_o_next = 1'b1;
            end else if (scl_i_reg) begin
                shift_next = {shift_r[6:0], sda_i_reg};
                bit_cnt_next = hc_add_3bit(bit_cnt, 3'b001);  // Use Han-Carlson adder
            end
            
            3'b100: begin
                state_next = 3'b000;
            end
            
            default: state_next = 3'b000;
        endcase
    end
    
    // Sequential logic with reset
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_r <= 3'b000;
            sda_oe <= 1'b1;
            scl_oe <= 1'b1;
            data_o <= 8'h00;
            valid_o <= 1'b0;
            bit_cnt <= 3'b000;
            shift_r <= 8'h00;
        end else begin
            state_r <= state_next;
            bit_cnt <= bit_cnt_next;
            shift_r <= shift_next;
            sda_oe <= sda_oe_next;
            valid_o <= valid_o_next;
            
            // Register data output to reduce output path delay
            if (state_next == 3'b100)
                data_o <= shift_next;
        end
    end
    
    // 3-bit Han-Carlson adder function
    function [2:0] hc_add_3bit;
        input [2:0] a;
        input [2:0] b;
        reg [2:0] sum;
        reg [2:0] p, g; // Propagate and generate signals
        reg [2:0] c; // Carry signals

        begin
            // Step 1: Generate P and G terms
            p[0] = a[0] ^ b[0]; // Propagate
            g[0] = a[0] & b[0]; // Generate
            
            p[1] = a[1] ^ b[1];
            g[1] = a[1] & b[1];
            
            p[2] = a[2] ^ b[2];
            g[2] = a[2] & b[2];
            
            // Step 2: Calculate carries (Han-Carlson style)
            c[0] = 1'b0; // No carry input
            c[1] = g[0]; // Carry from bit 0
            c[2] = g[1] | (p[1] & g[0]); // Carry from bit 1
            
            // Step 3: Calculate sum
            sum[0] = p[0] ^ c[0];
            sum[1] = p[1] ^ c[1];
            sum[2] = p[2] ^ c[2];
            
            hc_add_3bit = sum;
        end
    endfunction
    
    // 8-bit Han-Carlson adder module
    han_carlson_8bit hc_adder (
        .a(8'h00),
        .b(8'h00),
        .cin(1'b0),
        .sum(hc_sum),
        .cout(hc_cout)
    );
endmodule

// 8-bit Han-Carlson adder
module han_carlson_8bit (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] p, g; // Propagate and generate signals
    wire [7:0] pp, pg; // Pre-processed signals
    wire [7:0] c; // Carry signals
    
    // Step 1: Generate P and G terms (Preprocessing)
    assign p[0] = a[0] ^ b[0];
    assign g[0] = a[0] & b[0];
    assign p[1] = a[1] ^ b[1];
    assign g[1] = a[1] & b[1];
    assign p[2] = a[2] ^ b[2];
    assign g[2] = a[2] & b[2];
    assign p[3] = a[3] ^ b[3];
    assign g[3] = a[3] & b[3];
    assign p[4] = a[4] ^ b[4];
    assign g[4] = a[4] & b[4];
    assign p[5] = a[5] ^ b[5];
    assign g[5] = a[5] & b[5];
    assign p[6] = a[6] ^ b[6];
    assign g[6] = a[6] & b[6];
    assign p[7] = a[7] ^ b[7];
    assign g[7] = a[7] & b[7];
    
    // Step 2: First level of Han-Carlson prefix tree (even positions)
    // Compute group PG for even positions
    assign pp[0] = p[0];
    assign pg[0] = g[0] | (p[0] & cin);
    
    assign pp[2] = p[2] & p[1];
    assign pg[2] = g[2] | (p[2] & g[1]);
    
    assign pp[4] = p[4] & p[3];
    assign pg[4] = g[4] | (p[4] & g[3]);
    
    assign pp[6] = p[6] & p[5];
    assign pg[6] = g[6] | (p[6] & g[5]);
    
    // Step 3: Second level of Han-Carlson (even to even)
    wire [7:0] pp_lvl2, pg_lvl2;
    
    assign pp_lvl2[0] = pp[0];
    assign pg_lvl2[0] = pg[0];
    
    assign pp_lvl2[2] = pp[2] & pp[0];
    assign pg_lvl2[2] = pg[2] | (pp[2] & pg[0]);
    
    assign pp_lvl2[4] = pp[4] & pp[2];
    assign pg_lvl2[4] = pg[4] | (pp[4] & pg[2]);
    
    assign pp_lvl2[6] = pp[6] & pp[4];
    assign pg_lvl2[6] = pg[6] | (pp[6] & pg[4]);
    
    // Step 4: Third level - propagate to odd positions
    // Generate carries for all positions
    assign c[0] = cin;
    assign c[1] = pg[0];
    assign c[2] = pg_lvl2[2];
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = pg_lvl2[4];
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = pg_lvl2[6];
    assign c[7] = g[6] | (p[6] & c[6]);
    assign cout = g[7] | (p[7] & c[7]);
    
    // Step 5: Final sum computation (Postprocessing)
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
endmodule