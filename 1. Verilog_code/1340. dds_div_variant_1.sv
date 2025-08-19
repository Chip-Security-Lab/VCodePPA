//SystemVerilog
// Top-level module with pipelined architecture
module dds_div #(parameter FTW = 32'h1999_9999) (
    input  wire clk,     // System clock
    input  wire rst,     // Reset signal
    output wire clk_out  // Output clock
);

    // Internal pipeline signals
    wire [31:0] phase_accumulator_stage1;
    wire valid_stage1;
    
    // Instantiate pipelined phase accumulator submodule
    phase_accumulator_module #(
        .FTW(FTW)
    ) phase_acc_inst (
        .clk              (clk),
        .rst              (rst),
        .phase_accumulator(phase_accumulator_stage1),
        .valid_out        (valid_stage1)
    );
    
    // Instantiate pipelined output generator submodule
    output_generator_module output_gen_inst (
        .clk              (clk),
        .rst              (rst),
        .phase_accumulator(phase_accumulator_stage1),
        .valid_in         (valid_stage1),
        .clk_out          (clk_out)
    );

endmodule

// Pipelined phase accumulator submodule 
module phase_accumulator_module #(parameter FTW = 32'h1999_9999) (
    input  wire        clk,
    input  wire        rst,
    output reg  [31:0] phase_accumulator,
    output reg         valid_out
);
    // Pipeline registers
    reg [31:0] phase_accumulator_stage1;
    reg [31:0] phase_accumulator_stage2;
    reg        valid_stage1, valid_stage2;
    
    // Pipeline stage 1: Calculate phase increment
    always @(posedge clk) begin
        if (rst) begin
            phase_accumulator_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            phase_accumulator_stage1 <= phase_accumulator + FTW;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Update phase accumulator
    always @(posedge clk) begin
        if (rst) begin
            phase_accumulator_stage2 <= 32'b0;
            valid_stage2 <= 1'b0;
        end else begin
            phase_accumulator_stage2 <= phase_accumulator_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            phase_accumulator <= 32'b0;
            valid_out <= 1'b0;
        end else begin
            phase_accumulator <= phase_accumulator_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule

// Pipelined output generator submodule
module output_generator_module (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] phase_accumulator,
    input  wire        valid_in,
    output reg         clk_out
);
    // Pipeline registers
    reg [31:0] phase_acc_stage1, phase_acc_stage2;
    reg        valid_stage1, valid_stage2;
    reg        clk_out_stage1;
    
    // Pipeline stage 1: Register input
    always @(posedge clk) begin
        if (rst) begin
            phase_acc_stage1 <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            phase_acc_stage1 <= phase_accumulator;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Process phase information
    always @(posedge clk) begin
        if (rst) begin
            phase_acc_stage2 <= 32'b0;
            valid_stage2 <= 1'b0;
        end else begin
            phase_acc_stage2 <= phase_acc_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Generate output clock
    always @(posedge clk) begin
        if (rst) begin
            clk_out_stage1 <= 1'b0;
        end else if (valid_stage2) begin
            clk_out_stage1 <= phase_acc_stage2[31];
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= clk_out_stage1;
        end
    end

endmodule