//SystemVerilog
module pl_reg_async_load #(parameter W=8) (
    input clk, rst_n, load,
    input [W-1:0] async_data,
    output reg [W-1:0] q,
    // Pipeline control signals
    input valid_in,
    output reg valid_out,
    input ready_in,
    output reg ready_out
);

    // Pipeline stage registers
    reg [W-1:0] data_stage1;
    reg [W-1:0] data_stage2;
    reg load_stage1, load_stage2;
    reg valid_stage1, valid_stage2;
    
    // Handshaking logic
    wire stage1_ready = !valid_stage1 || (valid_stage1 && valid_stage2 && ready_in);
    wire stage2_ready = !valid_stage2 || (valid_stage2 && ready_in);
    
    // Stage 1: Data capture and load detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            load_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (stage1_ready) begin
            data_stage1 <= async_data;
            load_stage1 <= load;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Processing stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            load_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (stage2_ready) begin
            data_stage2 <= data_stage1;
            load_stage2 <= load_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n or posedge load_stage2) begin
        if (!rst_n) begin
            q <= 0;
            valid_out <= 0;
        end else if (load_stage2) begin
            q <= data_stage2;
            valid_out <= valid_stage2;
        end else if (ready_in && valid_stage2) begin
            valid_out <= valid_stage2;
        end
    end
    
    // Ready propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_out <= 0;
        end else begin
            ready_out <= stage1_ready;
        end
    end

endmodule