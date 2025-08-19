//SystemVerilog
// IEEE 1364-2005 Verilog standard
module s2p_shadow_reg #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             serial_in,
    input  wire             shift_en,
    input  wire             capture,
    output reg  [WIDTH-1:0] shadow_out,
    output wire [WIDTH-1:0] parallel_out
);
    // ===== Input Registration Stage =====
    reg             serial_data_r;
    reg             shift_enable_r;
    reg             capture_r;
    reg             input_valid_r;
    
    // ===== Shift Register Datapath =====
    reg [WIDTH-1:0] shift_register;
    
    // ===== Pipeline Control Signals =====
    reg             pipeline_valid_s1;
    reg             pipeline_valid_s2;
    reg             capture_s1;
    reg             capture_s2;
    
    // ===== Pipeline Datapath Registers =====
    reg [WIDTH-1:0] data_pipe_s1;
    reg [WIDTH-1:0] data_pipe_s2;
    
    // ========================================
    // Stage 0: Input Registration 
    // ========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_data_r   <= 1'b0;
            shift_enable_r  <= 1'b0;
            capture_r       <= 1'b0;
            input_valid_r   <= 1'b0;
        end else begin
            serial_data_r   <= serial_in;
            shift_enable_r  <= shift_en;
            capture_r       <= capture;
            input_valid_r   <= 1'b1;
        end
    end
    
    // ========================================
    // Stage 1: Shift Register Core Operation
    // ========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_register  <= {WIDTH{1'b0}};
            pipeline_valid_s1 <= 1'b0;
            capture_s1      <= 1'b0;
        end else if (input_valid_r) begin
            if (shift_enable_r) begin
                // Actual shift operation
                shift_register <= {shift_register[WIDTH-2:0], serial_data_r};
            end
            
            pipeline_valid_s1 <= input_valid_r;
            capture_s1      <= capture_r;
        end else begin
            pipeline_valid_s1 <= 1'b0;
        end
    end
    
    // ========================================
    // Stage 2: First Pipeline Stage
    // ========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe_s1    <= {WIDTH{1'b0}};
            pipeline_valid_s2 <= 1'b0;
            capture_s2      <= 1'b0;
        end else if (pipeline_valid_s1) begin
            data_pipe_s1    <= shift_register;
            pipeline_valid_s2 <= pipeline_valid_s1;
            capture_s2      <= capture_s1;
        end else begin
            pipeline_valid_s2 <= 1'b0;
        end
    end
    
    // ========================================
    // Stage 3: Final Pipeline Stage
    // ========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe_s2    <= {WIDTH{1'b0}};
        end else if (pipeline_valid_s2) begin
            data_pipe_s2    <= data_pipe_s1;
        end
    end
    
    // ========================================
    // Output Logic
    // ========================================
    // Parallel output from final pipeline stage
    assign parallel_out = data_pipe_s2;
    
    // Shadow register captures parallel data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out <= {WIDTH{1'b0}};
        end else if (pipeline_valid_s2 && capture_s2) begin
            shadow_out <= data_pipe_s1;
        end
    end

endmodule