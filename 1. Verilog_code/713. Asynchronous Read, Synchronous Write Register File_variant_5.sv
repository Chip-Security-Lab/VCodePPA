//SystemVerilog
module async_read_regfile #(
    parameter DW = 64,             // Data width
    parameter AW = 6,              // Address width
    parameter SIZE = (1 << AW),    // Register file size
    parameter PIPELINE_STAGES = 2  // Number of pipeline stages
)(
    input  wire           clock,
    input  wire           reset_n,
    input  wire           wr_en,
    input  wire [AW-1:0]  wr_addr,
    input  wire [DW-1:0]  wr_data,
    input  wire [AW-1:0]  rd_addr,
    output wire [DW-1:0]  rd_data,
    output wire           rd_valid
);

    // Storage element
    reg [DW-1:0] registers [0:SIZE-1];
    
    // Pipeline stage registers with buffered signals
    typedef struct packed {
        logic [AW-1:0] addr;
        logic          valid;
    } pipeline_stage_t;
    
    pipeline_stage_t [PIPELINE_STAGES-1:0] pipeline_regs;
    pipeline_stage_t [PIPELINE_STAGES-1:0] pipeline_regs_buf;
    
    // Write data path
    always @(posedge clock) begin
        if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end
    
    // Read pipeline stages with buffering
    generate
        for (genvar i = 0; i < PIPELINE_STAGES; i++) begin : pipeline_stages
            always @(posedge clock or negedge reset_n) begin
                if (!reset_n) begin
                    pipeline_regs[i].addr <= {AW{1'b0}};
                    pipeline_regs[i].valid <= 1'b0;
                    pipeline_regs_buf[i].addr <= {AW{1'b0}};
                    pipeline_regs_buf[i].valid <= 1'b0;
                end else begin
                    if (i == 0) begin
                        pipeline_regs[i].addr <= rd_addr;
                        pipeline_regs[i].valid <= 1'b1;
                    end else begin
                        pipeline_regs[i].addr <= pipeline_regs_buf[i-1].addr;
                        pipeline_regs[i].valid <= pipeline_regs_buf[i-1].valid;
                    end
                    pipeline_regs_buf[i].addr <= pipeline_regs[i].addr;
                    pipeline_regs_buf[i].valid <= pipeline_regs[i].valid;
                end
            end
        end
    endgenerate
    
    // Output assignments with buffered signals
    assign rd_data = registers[pipeline_regs_buf[PIPELINE_STAGES-1].addr];
    assign rd_valid = pipeline_regs_buf[PIPELINE_STAGES-1].valid;
    
endmodule