//SystemVerilog
module sync_controlled_bidir_shifter (
    input                 clock,
    input                 resetn,
    input      [31:0]     data_in,
    input      [4:0]      shift_amount,
    input      [1:0]      mode,  // 00:left logical, 01:right logical
                                  // 10:left rotate, 11:right rotate
    input                 valid_in,  // 输入数据有效信号
    output                ready_out, // 模块准备接收新数据
    output     [31:0]     data_out,
    output reg            valid_out  // 输出数据有效信号
);
    // Pipeline stage 1 registers
    reg [31:0] data_in_reg;
    reg [4:0]  shift_amount_reg;
    reg [1:0]  mode_reg;
    reg        valid_stage1;
    
    // Pipeline stage 2 registers
    reg [63:0] extended_data;
    reg [5:0]  effective_shift;
    reg [1:0]  mode_reg2;
    reg        valid_stage2;
    
    // Pipeline stage 3 register
    reg [31:0] shift_result;
    reg        valid_stage3;
    
    // Pipeline control signals
    reg [31:0] data_out_reg;
    wire       pipeline_ready;
    
    // Ready signal generation - pipeline is ready when not stalled
    assign ready_out = pipeline_ready;
    assign pipeline_ready = 1'b1; // Always ready in this implementation
    
    // Pipeline stage 1: Register inputs
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            data_in_reg <= 32'h0;
            shift_amount_reg <= 5'h0;
            mode_reg <= 2'h0;
            valid_stage1 <= 1'b0;
        end else if (valid_in && ready_out) begin
            data_in_reg <= data_in;
            shift_amount_reg <= shift_amount;
            mode_reg <= mode;
            valid_stage1 <= 1'b1;
        end else if (pipeline_ready) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Pipeline stage 2: Prepare operands
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            extended_data <= 64'h0;
            effective_shift <= 6'h0;
            mode_reg2 <= 2'h0;
            valid_stage2 <= 1'b0;
        end else if (pipeline_ready) begin
            // Create extended data for rotation operations
            extended_data <= {data_in_reg, data_in_reg};
            
            // Calculate effective shift amount
            case(mode_reg)
                2'b00: effective_shift <= {1'b0, shift_amount_reg};                  // Left logical
                2'b01: effective_shift <= {1'b0, shift_amount_reg};                  // Right logical
                2'b10: effective_shift <= {1'b0, 5'd32 - shift_amount_reg};          // Left rotate
                2'b11: effective_shift <= {1'b0, shift_amount_reg};                  // Right rotate
            endcase
            
            mode_reg2 <= mode_reg;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Perform shift operation
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            shift_result <= 32'h0;
            valid_stage3 <= 1'b0;
        end else if (pipeline_ready) begin
            case(mode_reg2)
                2'b00: shift_result <= data_in_reg << effective_shift[4:0];          // Left logical
                2'b01: shift_result <= data_in_reg >> effective_shift[4:0];          // Right logical
                2'b10: shift_result <= extended_data[31:0] >> effective_shift[4:0];  // Left rotate
                2'b11: shift_result <= extended_data[31:0] >> effective_shift[4:0];  // Right rotate
            endcase
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output register
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            data_out_reg <= 32'h0;
            valid_out <= 1'b0;
        end else if (pipeline_ready) begin
            data_out_reg <= shift_result;
            valid_out <= valid_stage3;
        end
    end
    
    // Assign output
    assign data_out = data_out_reg;
    
endmodule