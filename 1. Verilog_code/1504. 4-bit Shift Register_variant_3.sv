//SystemVerilog
// IEEE 1364-2005 Verilog Standard
module shift_reg_4bit_pipelined (
    input  wire       clk, rst, load_en, shift_en, serial_in,
    input  wire [3:0] parallel_data,
    output wire       serial_out,
    output wire [3:0] parallel_out
);

    // Optimized pipeline registers with reduced control signals
    reg [3:0] sr_stage1, sr_stage2;
    reg       valid_stage1, valid_stage2;
    reg       load_en_stage1;
    reg       shift_en_stage1;
    reg       serial_in_stage1;
    reg [3:0] parallel_data_stage1;

    // Stage 1: Input register - optimized reset handling
    always @(posedge clk) begin
        if (rst) begin
            sr_stage1           <= 4'b0;
            valid_stage1        <= 1'b0;
            load_en_stage1      <= 1'b0;
            shift_en_stage1     <= 1'b0;
            serial_in_stage1    <= 1'b0;
            parallel_data_stage1 <= 4'b0;
        end
        else begin
            sr_stage1           <= parallel_data;
            valid_stage1        <= 1'b1;
            load_en_stage1      <= load_en;
            shift_en_stage1     <= shift_en;
            serial_in_stage1    <= serial_in;
            parallel_data_stage1 <= parallel_data;
        end
    end

    // Stage 2: Optimized shift operation with priority-based logic
    always @(posedge clk) begin
        if (rst) begin
            sr_stage2    <= 4'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            // Optimized priority logic with case statement
            case ({load_en_stage1, shift_en_stage1})
                2'b10,  // Load has priority
                2'b11:  // Both active, load takes precedence
                    sr_stage2 <= parallel_data_stage1;
                    
                2'b01:  // Shift only
                    sr_stage2 <= {sr_stage1[2:0], serial_in_stage1};
                    
                2'b00:  // Hold
                    sr_stage2 <= sr_stage1;
            endcase
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Direct output connections
    assign serial_out   = sr_stage2[3];
    assign parallel_out = sr_stage2;

endmodule