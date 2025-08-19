//SystemVerilog
module sync_left_shifter_pipeline #(parameter W=32) (
    input  wire              Clock,
    input  wire              Reset,
    input  wire              Enable,
    input  wire  [W-1:0]     DataIn,
    input  wire  [4:0]       ShiftAmount,
    input  wire              DataInValid,
    output wire              DataOutReady,
    output reg   [W-1:0]     DataOut,
    output reg               DataOutValid
);

    // Stage 1 registers: Capture inputs
    reg [W-1:0]   data_in_stage1;
    reg [4:0]     shift_amt_stage1;
    reg           valid_stage1;

    // Stage 2 registers: Output of shift operation
    reg [W-1:0]   shifted_data_stage2;
    reg           valid_stage2;

    // Pipeline Ready/Valid handshake
    assign DataOutReady = 1'b1; // Always ready to accept new data

    // Stage 1: Input latch - DataIn
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            data_in_stage1 <= {W{1'b0}};
        end else if (Enable && DataInValid && DataOutReady) begin
            data_in_stage1 <= DataIn;
        end
    end

    // Stage 1: Input latch - ShiftAmount
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            shift_amt_stage1 <= 5'b0;
        end else if (Enable && DataInValid && DataOutReady) begin
            shift_amt_stage1 <= ShiftAmount;
        end
    end

    // Stage 1: Input latch - Valid
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            valid_stage1 <= 1'b0;
        end else if (Enable && DataInValid && DataOutReady) begin
            valid_stage1 <= 1'b1;
        end else if (!Enable) begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Shift operation - Data
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            shifted_data_stage2 <= {W{1'b0}};
        end else if (Enable) begin
            shifted_data_stage2 <= data_in_stage1 << shift_amt_stage1;
        end
    end

    // Stage 2: Shift operation - Valid
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            valid_stage2 <= 1'b0;
        end else if (Enable) begin
            valid_stage2 <= valid_stage1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Output stage - Data
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            DataOut <= {W{1'b0}};
        end else if (Enable) begin
            DataOut <= shifted_data_stage2;
        end
    end

    // Output stage - Valid
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            DataOutValid <= 1'b0;
        end else if (Enable) begin
            DataOutValid <= valid_stage2;
        end else begin
            DataOutValid <= 1'b0;
        end
    end

endmodule