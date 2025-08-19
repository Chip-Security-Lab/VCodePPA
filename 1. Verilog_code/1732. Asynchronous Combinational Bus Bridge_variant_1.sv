//SystemVerilog
// SystemVerilog
// Data path submodule with enhanced functionality
module async_bridge_data_path #(
    parameter WIDTH = 16,
    parameter PIPELINE_STAGES = 1
) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] a_data,
    input  logic data_en,
    output logic [WIDTH-1:0] b_data
);
    logic [WIDTH-1:0] data_reg [PIPELINE_STAGES-1:0];
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < PIPELINE_STAGES; i++) begin
                data_reg[i] <= '0;
            end
        end else if (data_en) begin
            data_reg[0] <= a_data;
            for (int i = 1; i < PIPELINE_STAGES; i++) begin
                data_reg[i] <= data_reg[i-1];
            end
        end
    end
    
    assign b_data = data_reg[PIPELINE_STAGES-1];
endmodule

// Control path submodule with handshake logic
module async_bridge_control #(
    parameter SYNC_STAGES = 2
) (
    input  logic clk,
    input  logic rst_n,
    input  logic a_valid,
    input  logic b_ready,
    output logic a_ready,
    output logic b_valid
);
    logic [SYNC_STAGES-1:0] valid_sync;
    logic [SYNC_STAGES-1:0] ready_sync;
    
    // Synchronize valid signal
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_sync <= '0;
        end else begin
            valid_sync <= {valid_sync[SYNC_STAGES-2:0], a_valid};
        end
    end
    
    // Synchronize ready signal
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_sync <= '0;
        end else begin
            ready_sync <= {ready_sync[SYNC_STAGES-2:0], b_ready};
        end
    end
    
    assign b_valid = valid_sync[SYNC_STAGES-1];
    assign a_ready = ready_sync[SYNC_STAGES-1];
endmodule

// Top-level module with enhanced features
module async_bridge #(
    parameter WIDTH = 16,
    parameter PIPELINE_STAGES = 1,
    parameter SYNC_STAGES = 2
) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] a_data,
    input  logic a_valid,
    input  logic b_ready,
    output logic [WIDTH-1:0] b_data,
    output logic a_ready,
    output logic b_valid
);
    logic data_en;
    
    // Generate data enable signal
    assign data_en = a_valid && a_ready;
    
    // Instantiate data path submodule
    async_bridge_data_path #(
        .WIDTH(WIDTH),
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) data_path_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_data(a_data),
        .data_en(data_en),
        .b_data(b_data)
    );
    
    // Instantiate control path submodule
    async_bridge_control #(
        .SYNC_STAGES(SYNC_STAGES)
    ) control_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_valid(a_valid),
        .b_ready(b_ready),
        .a_ready(a_ready),
        .b_valid(b_valid)
    );
endmodule